package com.amiya.health.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.amiya.health.ui.theme.AmiyaDark
import com.amiya.health.ui.theme.AmiyaGray
import com.amiya.health.ui.theme.AmiyaPurple

@Composable
fun HomeScreen(
    onStartCheckup: (String) -> Unit,
    onViewDashboard: () -> Unit
) {
    var patientName by remember { mutableStateOf("") }
    var nameError by remember { mutableStateOf(false) }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.radialGradient(
                    colors = listOf(Color.White, Color(0xFFF3EEFF)),
                    radius = 1200f
                )
            )
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(Modifier.height(60.dp))

            // Logo / Header
            Text(
                text = "Amiya",
                style = MaterialTheme.typography.headlineLarge.copy(
                    fontSize = 48.sp,
                    color = AmiyaDark
                )
            )
            Text(
                text = "Your AI Health Companion",
                style = MaterialTheme.typography.bodyLarge.copy(color = AmiyaGray),
                modifier = Modifier.padding(top = 8.dp)
            )

            Spacer(Modifier.height(60.dp))

            // Welcome card
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
            ) {
                Column(
                    modifier = Modifier.padding(24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = "Start a Checkup",
                        style = MaterialTheme.typography.headlineMedium.copy(color = AmiyaDark),
                        textAlign = TextAlign.Center
                    )

                    Spacer(Modifier.height(8.dp))

                    Text(
                        text = "Connect with an AI doctor for a personalized health consultation",
                        style = MaterialTheme.typography.bodyMedium.copy(color = AmiyaGray),
                        textAlign = TextAlign.Center
                    )

                    Spacer(Modifier.height(24.dp))

                    OutlinedTextField(
                        value = patientName,
                        onValueChange = {
                            patientName = it
                            nameError = false
                        },
                        label = { Text("Your Name") },
                        placeholder = { Text("Enter your full name") },
                        isError = nameError,
                        supportingText = if (nameError) {
                            { Text("Please enter your name") }
                        } else null,
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                        shape = RoundedCornerShape(12.dp)
                    )

                    Spacer(Modifier.height(16.dp))

                    Button(
                        onClick = {
                            if (patientName.isBlank()) {
                                nameError = true
                            } else {
                                onStartCheckup(patientName.trim())
                            }
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(52.dp),
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = AmiyaPurple)
                    ) {
                        Text(
                            text = "Begin Checkup",
                            color = AmiyaDark,
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 16.sp
                        )
                    }
                }
            }

            Spacer(Modifier.height(16.dp))

            TextButton(onClick = onViewDashboard) {
                Text(
                    text = "View past checkups",
                    color = AmiyaGray,
                    style = MaterialTheme.typography.bodyMedium
                )
            }

            Spacer(Modifier.weight(1f))

            // Feature bullets
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                FeaturePill("Private")
                FeaturePill("On-Device AI")
                FeaturePill("Free")
            }

            Spacer(Modifier.height(24.dp))
        }
    }
}

@Composable
private fun FeaturePill(label: String) {
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(20.dp))
            .background(Color(0xFFEDE9FE))
            .padding(horizontal = 16.dp, vertical = 8.dp)
    ) {
        Text(
            text = label,
            color = Color(0xFF6D28D9),
            style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Medium)
        )
    }
}
