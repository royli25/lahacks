package com.amiya.health.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import com.amiya.health.ui.screens.*

sealed class Screen(val route: String) {
    object Home : Screen("home")
    object Auth : Screen("auth")
    object DoctorSelection : Screen("doctor_selection/{patientName}") {
        fun createRoute(patientName: String) = "doctor_selection/$patientName"
    }
    object PhoneEntry : Screen("phone_entry/{patientName}/{doctorId}/{doctorName}") {
        fun createRoute(patientName: String, doctorId: String, doctorName: String) =
            "phone_entry/$patientName/$doctorId/${doctorName.replace("/", "|")}"
    }
    object Dashboard : Screen("dashboard/{uid}/{patientName}/{doctorName}") {
        fun createRoute(uid: String, patientName: String, doctorName: String) =
            "dashboard/$uid/$patientName/${doctorName.replace("/", "|")}"
    }
    object Checkup : Screen("checkup/{uid}/{patientName}/{doctorId}/{doctorName}") {
        fun createRoute(uid: String, patientName: String, doctorId: String, doctorName: String) =
            "checkup/$uid/$patientName/$doctorId/${doctorName.replace("/", "|")}"
    }
}

@Composable
fun NavGraph(navController: NavHostController) {
    NavHost(navController = navController, startDestination = Screen.Home.route) {

        composable(Screen.Home.route) {
            HomeScreen(
                onStartCheckup = { patientName ->
                    navController.navigate(Screen.DoctorSelection.createRoute(patientName))
                },
                onViewDashboard = { navController.navigate(Screen.Auth.route) }
            )
        }

        composable(Screen.Auth.route) {
            AuthScreen(
                onAuthSuccess = { uid, name, doctor ->
                    navController.navigate(Screen.Dashboard.createRoute(uid, name, doctor))
                },
                onBack = { navController.popBackStack() }
            )
        }

        composable(
            route = Screen.DoctorSelection.route,
            arguments = listOf(navArgument("patientName") { type = NavType.StringType })
        ) { backStack ->
            val patientName = backStack.arguments?.getString("patientName") ?: ""
            DoctorSelectionScreen(
                patientName = patientName,
                onDoctorSelected = { doctorId, doctorName ->
                    navController.navigate(
                        Screen.PhoneEntry.createRoute(patientName, doctorId, doctorName)
                    )
                },
                onBack = { navController.popBackStack() }
            )
        }

        composable(
            route = Screen.PhoneEntry.route,
            arguments = listOf(
                navArgument("patientName") { type = NavType.StringType },
                navArgument("doctorId") { type = NavType.StringType },
                navArgument("doctorName") { type = NavType.StringType }
            )
        ) { backStack ->
            val patientName = backStack.arguments?.getString("patientName") ?: ""
            val doctorId = backStack.arguments?.getString("doctorId") ?: ""
            val doctorName = backStack.arguments?.getString("doctorName")?.replace("|", "/") ?: ""
            PhoneEntryScreen(
                patientName = patientName,
                doctorId = doctorId,
                doctorName = doctorName,
                onRegistered = { uid ->
                    navController.navigate(
                        Screen.Checkup.createRoute(uid, patientName, doctorId, doctorName)
                    )
                },
                onBack = { navController.popBackStack() }
            )
        }

        composable(
            route = Screen.Dashboard.route,
            arguments = listOf(
                navArgument("uid") { type = NavType.StringType },
                navArgument("patientName") { type = NavType.StringType },
                navArgument("doctorName") { type = NavType.StringType }
            )
        ) { backStack ->
            val uid = backStack.arguments?.getString("uid") ?: ""
            val patientName = backStack.arguments?.getString("patientName") ?: ""
            val doctorName = backStack.arguments?.getString("doctorName")?.replace("|", "/") ?: ""
            DashboardScreen(
                uid = uid,
                patientName = patientName,
                doctorName = doctorName,
                onStartCheckup = { doctorId ->
                    navController.navigate(
                        Screen.Checkup.createRoute(uid, patientName, doctorId, doctorName)
                    )
                },
                onBack = { navController.popBackStack() }
            )
        }

        composable(
            route = Screen.Checkup.route,
            arguments = listOf(
                navArgument("uid") { type = NavType.StringType },
                navArgument("patientName") { type = NavType.StringType },
                navArgument("doctorId") { type = NavType.StringType },
                navArgument("doctorName") { type = NavType.StringType }
            )
        ) { backStack ->
            val uid = backStack.arguments?.getString("uid") ?: ""
            val patientName = backStack.arguments?.getString("patientName") ?: ""
            val doctorId = backStack.arguments?.getString("doctorId") ?: ""
            val doctorName = backStack.arguments?.getString("doctorName")?.replace("|", "/") ?: ""
            CheckupScreen(
                uid = uid,
                patientName = patientName,
                doctorId = doctorId,
                doctorName = doctorName,
                onCallEnded = {
                    navController.navigate(Screen.Home.route) {
                        popUpTo(Screen.Home.route) { inclusive = true }
                    }
                }
            )
        }
    }
}
