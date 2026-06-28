import com.android.build.gradle.BaseExtension
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinJvmCompile

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
    plugins.withId("com.android.application") {
        extensions.findByType(BaseExtension::class.java)?.compileOptions {
            sourceCompatibility = JavaVersion.VERSION_17
            targetCompatibility = JavaVersion.VERSION_17
        }
    }
    plugins.withId("com.android.library") {
        extensions.findByType(BaseExtension::class.java)?.compileOptions {
            sourceCompatibility = JavaVersion.VERSION_17
            targetCompatibility = JavaVersion.VERSION_17
        }
        if (project.name == "camera_android_camerax") {
            dependencies.add("implementation", "androidx.camera:camera-core:1.4.1")
            dependencies.add("implementation", "androidx.camera:camera-camera2:1.4.1")
            dependencies.add("implementation", "androidx.camera:camera-lifecycle:1.4.1")
            dependencies.add("implementation", "androidx.camera:camera-video:1.4.1")
        }
        if (project.name == "google_mlkit_commons") {
            dependencies.add("implementation", "com.google.mlkit:common:18.11.0")
            dependencies.add("implementation", "com.google.android.gms:play-services-tasks:18.4.0")
        }
    }
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = JavaVersion.VERSION_17.toString()
        targetCompatibility = JavaVersion.VERSION_17.toString()
    }
    tasks.withType<KotlinJvmCompile>().configureEach {
        compilerOptions {
            val target = if (project.name == "file_picker" || project.name == "tflite_flutter") {
                JvmTarget.JVM_11
            } else {
                JvmTarget.JVM_17
            }
            jvmTarget.set(target)
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
