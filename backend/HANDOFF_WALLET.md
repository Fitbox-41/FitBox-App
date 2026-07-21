# Handoff — Shared Points Wallet (for the Website)

**For:** Diwakar (website backend)
**From:** Gautam (app + app-backend)
**Goal:** one points balance shared across the app and the website. The user **earns** points in
the app and **redeems** (spends) them at website checkout. There is **one balance and one ledger** in
the shared MongoDB — no copies, no syncing.

This doc is the contract. Read it top to bottom; everything you need to build the checkout redeem is here.

> **STATUS (updated 20 Jul 2026): IMPLEMENTED on both sides + schema updated.** Checkout redeem/refund
> are live on the website; credit/redeem/read are live on the app backend. **Key schema change:** the
> balance now lives **on the user document** (`users.walletBalance`) — the separate `wallets` collection
> was removed (so the balance is visible right in the `users` collection). The `wallet_transactions`
> ledger is unchanged. Conversion is set to **1 point = ₹2**. Details below reflect the current design.

---

## 1. The big picture

```
  App / admin / territory (trusted servers)          Website checkout (you)
            │  POST /api/wallet/credit                        │  POST /api/wallet/redeem
            ▼                                                 ▼
        ┌─────────────────────  App backend  ─────────────────────┐
        │   https://fit-box-app.vercel.app                        │
        │   owns ALL wallet writes (credit + debit), atomic +     │
        │   idempotent. This is the ONLY code that mutates points.│
        └───────────────────────────┬─────────────────────────────┘
                                     ▼
                    Shared MongoDB Atlas (same cluster as the website)
                    balance:  users.walletBalance   |   history:  wallet_transactions
```

**Rule we agreed:** all point changes go through the **app backend** so the ledger logic (atomic
balance update + idempotency + never-go-negative) lives in one place. You call the app backend endpoint to
mutate — don't `$inc` `users.walletBalance` or write `wallet_transactions` directly from the website. You
may **read** `users.walletBalance` directly for display (same cluster), or call the read endpoint (see §5).
_(Note: the website's own checkout redeem/refund do write via `$inc` inside their order transaction — that's
the agreed exception, kept atomic with the order; everything else routes through the app backend.)_

---

## 2. Where wallet data lives (current schema)

### Balance → on the **`users`** document
The points balance is a field on the user doc, so it shows up right in the `users` collection:

| field                | type                    | notes                                        |
|----------------------|-------------------------|----------------------------------------------|
| `users.walletBalance`| Number (integer points) | one per user, never negative, default 0      |

There is **no separate `wallets` collection** anymore (removed 20 Jul 2026). Balances were migrated by
recomputing from the ledger (see §9 `reconcile`).

### `wallet_transactions` — append-only ledger (the history, kept separate)
| field            | type                    | notes                                                        |
|------------------|-------------------------|--------------------------------------------------------------|
| `userId`         | ObjectId (ref `users`)  |                                                              |
| `type`           | `'credit'` \| `'debit'` | credit = earned, debit = redeemed                            |
| `amount`         | Number (> 0)            | always positive; `type` gives direction                      |
| `balanceAfter`   | Number                  | wallet balance immediately after this entry                  |
| `source`         | String                  | e.g. `checkout_redeem`, `admin_adjust`, `territory_reward`   |
| `sourceId`       | String (optional)       | the related id — **for redeem, the `orderId`**               |
| `idempotencyKey` | String, **unique**      | prevents double-apply (see §4) — this is the safety net      |
| `description`    | String (optional)       | human-readable, e.g. "Redeemed at checkout for order #123"   |
| `createdAt`      | Date                    | auto                                                         |

> Invariant: `users.walletBalance` always equals the signed sum of that user's `wallet_transactions`.
> Because every write is one atomic transaction, this can never drift (and `reconcile` re-derives it).

---

## 3. The endpoint you call — `POST /api/wallet/redeem`

Debits (spends) a user's points. Use this at checkout when the user chooses to pay with points.

- **URL:** `https://fit-box-app.vercel.app/api/wallet/redeem`
- **Auth:** server-to-server. Header **`X-Service-Key: <WALLET_SERVICE_KEY>`** (see §6). This is a
  server-only secret — call it from your **website backend**, never from the browser.
- **Body (JSON):**
  ```json
  {
    "userId": "665f...",            // the customer's Mongo _id
    "amount": 50,                    // points to spend (positive integer)
    "source": "checkout_redeem",
    "sourceId": "<orderId>",         // the order this redemption pays for
    "idempotencyKey": "redeem-<orderId>",   // see §4 — MUST be stable per order
    "description": "Redeemed at checkout for order #123"
  }
  ```
- **Success `200`:**
  ```json
  { "success": true, "balance": 120, "transaction": { ...ledger row... } }
  ```
  `balance` is the new balance after the debit.
- **Already processed `200`** (you sent the same `idempotencyKey` again):
  ```json
  { "success": true, "message": "Already processed", "transaction": { ... } }
  ```
  Treat this exactly like success — the debit happened once.
- **Not enough points `400`:** `{ "success": false, "message": "Insufficient balance" }`
- **Bad input `400`:** invalid `userId` / non-positive `amount` / missing `idempotencyKey`.
- **Bad/missing service key `403`:** `{ "success": false, "message": "Service authentication required" }`

For reference, crediting (earning) uses the same shape at `POST /api/wallet/credit` — but that's called
by the app/admin/territory side, not you.

---

## 4. Idempotency — the one thing you must get right

Networks retry. A checkout can fire twice (double-click, retry, webhook re-delivery). If two identical
redeems both applied, the user would be charged points twice.

**The fix:** send a **stable `idempotencyKey` tied to the order**, e.g. `redeem-<orderId>`. The app
backend records it with a unique index. The **first** call applies the debit; any repeat with the same
key returns the original transaction and changes nothing. So it is always safe to retry.

- Use the **same** key for retries of the **same** redemption.
- Use a **different** key only for a genuinely different redemption.
- If a user redeems on one order, then redeems again on a *different* order, those are different keys.

---

## 5. Showing the balance on the website

Two options — pick whichever fits your code:

**A. Read it straight off the user doc (simplest — this is what the website now does).**
```js
const user = await User.findById(userId).select('walletBalance');
const points = user?.walletBalance ?? 0;
```
Reading is safe to do directly. **Writing must still go through the app backend** (§3) so the ledger
stays correct — never `$inc` the balance from two services independently.

**B. Call the read endpoint** `GET /api/wallet` with the **user's** JWT (`Authorization: Bearer <token>`)
— returns `{ success, balance, transactions }`. Handy if you want the transaction history too.

---

## 6. The one secret we must share — `WALLET_SERVICE_KEY`

`redeem`/`credit` are gated by a shared server-to-server secret so end users can't mutate their own
points. We need the **same value** on both backends:

1. Generate one long random value: `openssl rand -hex 32`.
2. Set it as `WALLET_SERVICE_KEY` in the **app backend** Vercel env (Gautam) **and** in the **website
   backend** env (you).
3. The website reads it from `process.env.WALLET_SERVICE_KEY` and sends it as the `X-Service-Key` header.

Until this is set on the app backend, `redeem`/`credit` return `503 "Wallet mutations are not configured"`
(fail-closed by design). Reads (`GET /api/wallet`) work regardless.

---

## 7. The redeem rule — **decided** ✅

- **Conversion: `1 point = ₹2`** (set in `POINT_VALUE_INR`, both the website checkout and the Cart UI).
- **Cap:** the checkout caps points-usable at the order value; points are integers.

At checkout, convert the points the user wants to spend into a discount, cap at the order total, then the
website's `placeOrder` debits the balance atomically inside the order transaction (idempotent per order —
see §4). On `Insufficient balance`, show "not enough points" and don't apply the discount.

---

## 8. Suggested checkout flow

1. User is at checkout, has points. Show balance (§5) and a "pay with points" input.
2. User enters points to use → convert to discount (§7), update the order total in the UI.
3. On **place order**, in your backend, **after** the order is created (you have an `orderId`):
   - Call `POST /api/wallet/redeem` with `userId`, `amount` (points), `sourceId: orderId`,
     `idempotencyKey: "redeem-" + orderId`, `X-Service-Key`.
   - On `success` (or `Already processed`): finalize the order with the discount applied.
   - On `400 Insufficient balance`: reject/adjust — the user doesn't have the points.
4. If the order later fails/refunds and you want to give points back, credit them back via a
   compensating entry (ask Gautam — we'll add a `refund` path with its own idempotency key).

---

## 9. How to test (5 minutes, once `WALLET_SERVICE_KEY` is set)

Use a real test user's `_id`. Replace `KEY` and `UID`.

```bash
BASE=https://fit-box-app.vercel.app/api/wallet
KEY=your_service_key
UID=the_test_user_mongo_id

# 1) Give the test user 100 points (credit)
curl -s -X POST $BASE/credit -H "Content-Type: application/json" -H "X-Service-Key: $KEY" \
  -d "{\"userId\":\"$UID\",\"amount\":100,\"source\":\"admin_adjust\",\"idempotencyKey\":\"seed-$UID-1\",\"description\":\"test seed\"}"

# 2) Redeem 30 for an order -> balance should become 70
curl -s -X POST $BASE/redeem -H "Content-Type: application/json" -H "X-Service-Key: $KEY" \
  -d "{\"userId\":\"$UID\",\"amount\":30,\"sourceId\":\"order-TEST\",\"idempotencyKey\":\"redeem-order-TEST\"}"

# 3) Send the SAME redeem again -> "Already processed", balance stays 70 (idempotency works)
curl -s -X POST $BASE/redeem -H "Content-Type: application/json" -H "X-Service-Key: $KEY" \
  -d "{\"userId\":\"$UID\",\"amount\":30,\"sourceId\":\"order-TEST\",\"idempotencyKey\":\"redeem-order-TEST\"}"

# 4) Try to redeem 1000 (more than balance) -> 400 Insufficient balance
curl -s -X POST $BASE/redeem -H "Content-Type: application/json" -H "X-Service-Key: $KEY" \
  -d "{\"userId\":\"$UID\",\"amount\":1000,\"sourceId\":\"order-X\",\"idempotencyKey\":\"redeem-order-X\"}"
```

Then confirm the same balance shows in the app (Wallet tab) and on the website profile — proving it's
**one balance everywhere**.

---

## 10. Status / done

- [x] **Conversion** confirmed: 1 point = ₹2 (§7).
- [x] **Schema**: balance moved to `users.walletBalance`; `wallets` collection removed; ledger unchanged (§2).
- [x] **`WALLET_SERVICE_KEY`** set on both backends (§6).
- [x] **Refund/return path**: implemented on cancel + failed-payment (credits points back, idempotent).
- [x] **Migration/integrity:** `POST /api/wallet/reconcile` (service-key) recomputes every user's
      `walletBalance` from the ledger — used for the migration and available anytime as a repair tool.
      Optional body `{ "userId": "<id>" }` returns that user's balance to verify.

Questions → Gautam.
