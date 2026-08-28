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
    project.evaluationDependsOn(":app")
}

// Certains plugins tiers (ex: flutter_facebook_auth) ne fixent que la cible
// Java (souvent 1.8) sans fixer la cible Kotlin correspondante. Avec JDK 21
// comme toolchain, le Kotlin Gradle Plugin 2.x cible alors 21 par défaut,
// créant une incohérence Java/Kotlin que la compilation refuse. On force
// donc une cible Java+Kotlin cohérente sur tous les sous-projets plutôt que
// d'attendre que chaque plugin la corrige. 17 plutôt que 11 (cible de notre
// propre module :app) : certains plugins (ex: google_maps_flutter_android)
// utilisent une syntaxe Java récente (switch expressions, pattern matching
// instanceof) qui exige au moins Java 16 pour compiler.
subprojects {
    // :app fixe déjà sa propre cible (11) dans son build.gradle.kts — pas
    // besoin de la retoucher ici. Ce correctif ne vise que les modules des
    // plugins tiers ; Android/D8 gère très bien des modules compilés à des
    // cibles Java différentes au sein d'un même projet.
    if (project.path == ":app") return@subprojects

    // afterEvaluate : chaque plugin (ex: firebase_app_check) fixe sa propre
    // cible Java dans LE CORPS de son build.gradle, qui s'exécute après
    // l'application du plugin — un `tasks.withType(...).configureEach`
    // enregistré ici (avant) se ferait donc écraser ensuite. afterEvaluate
    // garantit qu'on s'exécute une fois le script du plugin entièrement
    // évalué, donc en dernier, donc qu'on gagne toujours.
    afterEvaluate {
        // Le contrôle de cohérence de Kotlin Gradle Plugin lit
        // `android.compileOptions` (l'extension), pas les propriétés de la
        // tâche `JavaCompile` — reconfigurer la tâche directement (essayé
        // avant) n'a donc aucun effet sur ce contrôle précis.
        extensions.findByType<com.android.build.gradle.BaseExtension>()
            ?.compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
