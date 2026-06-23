allprojects {
    repositories {
        mavenLocal()
        maven { url = uri("https://storage.flutter-io.cn/download.flutter.io") }
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/central") }
        google()
        mavenCentral()
    }
    configurations.all {
        resolutionStrategy {
            // Fix gal/AGP: lint 31.5.2 not in Maven, use 31.4.2
            force("com.android.tools.lint:lint-api:31.4.2")
            force("com.android.tools.lint:lint-checks:31.4.2")
            eachDependency {
                if (requested.group == "com.android.tools.lint") {
                    useVersion("31.4.2")
                    because("lint 31.5.2 not available in Maven")
                }
            }
        }
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
    project.evaluationDependsOn(":app")
}
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
