allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    // Some plugins (e.g. `health` 13.0.0) hardcode an old compileSdk (34) that
    // is lower than what their own transitive dependencies require
    // (androidx.health.connect:connect-client needs 35+), which breaks the
    // release AAR-metadata check. Force every plugin module up to our compileSdk
    // so the whole project compiles against the same, high-enough API level.
    // (`:app` already sets compileSdk 36 directly and is evaluated first below,
    // so it's excluded to avoid registering afterEvaluate on an evaluated project.)
    if (name != "app") {
        afterEvaluate {
            val android = extensions.findByName("android") ?: return@afterEvaluate
            val methods = android.javaClass.methods
            val setCompileSdk = methods.firstOrNull {
                it.name == "setCompileSdk" && it.parameterCount == 1 &&
                    it.parameterTypes[0] == Integer::class.java
            }
            if (setCompileSdk != null) {
                setCompileSdk.invoke(android, 36)
            } else {
                methods.firstOrNull {
                    it.name == "compileSdkVersion" && it.parameterCount == 1 &&
                        it.parameterTypes[0] == Integer.TYPE
                }?.invoke(android, 36)
            }
        }
    }
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
