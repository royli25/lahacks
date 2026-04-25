package com.amiya.health.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.OffsetMapping
import androidx.compose.ui.text.input.TransformedText
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.amiya.health.api.ApiClient
import com.amiya.health.data.models.NewPatientRequest
import com.amiya.health.ui.theme.AmiyaDark
import com.amiya.health.ui.theme.AmiyaGray
import com.amiya.health.ui.theme.AmiyaPurple
import kotlinx.coroutines.launch

@Composable
fun PhoneEntryScreen(
    patientName: String,
    doctorId: String,
    doctorName: String,
    onRegistered: (uid: String) -> Unit,
    onBack: () -> Unit
) {
    var rawPhone by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf("") }
    val scope = rememberCoroutineScope()

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
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(onClick = onBack) {
                    Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                }
                Spacer(Modifier.width(8.dp))
                Text(
                    text = "Enter Phone Number",
                    style = MaterialTheme.typography.headlineMedium.copy(color = AmiyaDark)
                )
            }

            Spacer(Modifier.height(8.dp))

            Text(
                text = "We'll send your appointment link via SMS",
                style = MaterialTheme.typography.bodyMedium.copy(color = AmiyaGray),
                modifier = Modifier.padding(start = 48.dp).fillMaxWidth()
            )

            Spacer(Modifier.height(32.dp))

            // Appointment summary card
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = Color(0xFFF5F0FF)),
                elevation = CardDefaults.cardElevation(0.dp)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "Appointment Summary",
                        style = MaterialTheme.typography.bodyLarge.copy(
                            fontWeight = FontWeight.SemiBold,
                            color = AmiyaDark
                        )
                    )
                    Spacer(Modifier.height(8.dp))
                    SummaryRow("Patient", patientName)
                    SummaryRow("Doctor", doctorName)
                }
            }

            Spacer(Modifier.height(24.dp))

            OutlinedTextField(
                value = rawPhone,
                onValueChange = { input ->
                    val digits = input.filter { it.isDigit() }.take(10)
                    rawPhone = digits
                    errorMessage = ""
                },
                label = { Text("Phone Number") },
                placeholder = { Text("(555) 555-5555") },
                visualTransformation = PhoneVisualTransformation(),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
                isError = errorMessage.isNotEmpty(),
                supportingText = if (errorMessage.isNotEmpty()) {
                    { Text(errorMessage) }
                } else null,
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                shape = RoundedCornerShape(12.dp)
            )

            Spacer(Modifier.height(24.dp))

            Button(
                onClick = {
                    if (rawPhone.length < 10) {
                        errorMessage = "Please enter a valid 10-digit phone number"
                        return@Button
                    }
                    val formatted = "+1${rawPhone}"
                    scope.launch {
                        isLoading = true
                        try {
                            val response = ApiClient.service.registerPatient(
                                NewPatientRequest(
                                    name = patientName,
                                    phoneNumber = formatted,
                                    agentName = doctorName
                                )
                            )
                            if (response.isSuccessful) {
                                val body = response.body()
                                if (body != null) {
                                    onRegistered(body.uid)
                                } else {
                                    errorMessage = "Registration failed. Try again."
                                }
                            } else {
                                errorMessage = "Server error: ${response.code()}"
                            }
                        } catch (e: Exception) {
                            errorMessage = "Network error: ${e.message}"
                        } finally {
                            isLoading = false
                        }
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(containerColor = AmiyaPurple),
                enabled = rawPhone.length == 10 && !isLoading
            ) {
                if (isLoading) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        color = AmiyaDark,
                        strokeWidth = 2.dp
                    )
                } else {
                    Text(
                        text = "Start Checkup",
                        color = AmiyaDark,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 16.sp
                    )
                }
            }
        }
    }
}

@Composable
private fun SummaryRow(label: String, value: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp)
    ) {
        Text(
            text = "$label: ",
            style = MaterialTheme.typography.bodyMedium.copy(color = AmiyaGray)
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium.copy(
                color = AmiyaDark,
                fontWeight = FontWeight.Medium
            )
        )
    }
}

class PhoneVisualTransformation : VisualTransformation {
    override fun filter(text: AnnotatedString): TransformedText {
        val digits = text.text
        val formatted = buildString {
            digits.forEachIndexed { index, c ->
                when (index) {
                    0 -> append("($c")
                    3 -> append(") $c")
                    6 -> append("-$c")
                    else -> append(c)
                }
            }
        }

        val offsetMapping = object : OffsetMapping {
            override fun originalToTransformed(offset: Int): Int = when {
                offset == 0 -> 0
                offset <= 3 -> offset + 1
                offset <= 6 -> offset + 3
                else -> offset + 4
            }.coerceAtMost(formatted.length)

            override fun transformedToOriginal(offset: Int): Int = when {
                offset <= 1 -> 0
                offset <= 5 -> offset - 1
                offset <= 9 -> offset - 3
                else -> offset - 4
            }.coerceAtMost(digits.length)
        }

        return TransformedText(AnnotatedString(formatted), offsetMapping)
    }
}
