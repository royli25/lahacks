package com.amiya.health.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowUp
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.amiya.health.data.models.CheckupRecord
import com.amiya.health.data.models.TranscriptEntry
import com.amiya.health.ui.theme.AmiyaDark
import com.amiya.health.ui.theme.AmiyaGray
import com.amiya.health.ui.theme.AmiyaPurple

@Composable
fun DashboardScreen(
    uid: String,
    patientName: String,
    doctorName: String,
    onStartCheckup: (doctorId: String) -> Unit,
    onBack: () -> Unit
) {
    // Demo checkup history
    val checkups = remember {
        listOf(
            CheckupRecord(
                id = "1",
                date = "April 24, 2026",
                duration = "12 min",
                status = "completed",
                doctorName = doctorName,
                summary = "Patient reported mild fatigue and occasional headaches. Blood pressure within normal range. Recommended increased hydration and follow-up in 2 weeks.",
                transcript = listOf(
                    TranscriptEntry("Doctor", "Hello! How are you feeling today?"),
                    TranscriptEntry("Patient", "I've been feeling a bit tired lately."),
                    TranscriptEntry("Doctor", "Can you describe the fatigue? When did it start?"),
                    TranscriptEntry("Patient", "About a week ago. I also get headaches sometimes.")
                ),
                nextSteps = listOf(
                    "Drink 8 glasses of water daily",
                    "Follow up in 2 weeks",
                    "Track headache frequency and severity"
                )
            )
        )
    }

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
        Column(modifier = Modifier.fillMaxSize()) {
            // Header
            Surface(
                color = Color.White,
                shadowElevation = 2.dp
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                    Spacer(Modifier.width(8.dp))
                    Column {
                        Text(
                            text = patientName,
                            style = MaterialTheme.typography.headlineMedium.copy(color = AmiyaDark)
                        )
                        Text(
                            text = "Patient Dashboard · UID: $uid",
                            style = MaterialTheme.typography.bodySmall.copy(color = AmiyaGray)
                        )
                    }
                }
            }

            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                item {
                    // Quick start card
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(16.dp),
                        colors = CardDefaults.cardColors(containerColor = AmiyaPurple.copy(alpha = 0.15f)),
                        elevation = CardDefaults.cardElevation(0.dp)
                    ) {
                        Row(
                            modifier = Modifier.padding(16.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = "Start New Checkup",
                                    style = MaterialTheme.typography.bodyLarge.copy(
                                        fontWeight = FontWeight.SemiBold,
                                        color = AmiyaDark
                                    )
                                )
                                Text(
                                    text = "With $doctorName",
                                    style = MaterialTheme.typography.bodyMedium.copy(color = AmiyaGray)
                                )
                            }
                            Button(
                                onClick = { onStartCheckup("alpha") },
                                shape = RoundedCornerShape(12.dp),
                                colors = ButtonDefaults.buttonColors(containerColor = AmiyaPurple)
                            ) {
                                Text("Begin", color = AmiyaDark, fontWeight = FontWeight.SemiBold)
                            }
                        }
                    }
                }

                item {
                    Text(
                        text = "Past Checkups",
                        style = MaterialTheme.typography.bodyLarge.copy(
                            fontWeight = FontWeight.SemiBold,
                            color = AmiyaDark
                        )
                    )
                }

                items(checkups) { checkup ->
                    CheckupCard(checkup = checkup)
                }

                if (checkups.isEmpty()) {
                    item {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(32.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = "No checkups yet. Start your first one!",
                                style = MaterialTheme.typography.bodyMedium.copy(color = AmiyaGray)
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun CheckupCard(checkup: CheckupRecord) {
    var expanded by remember { mutableStateOf(false) }
    var transcriptExpanded by remember { mutableStateOf(false) }

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(2.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { expanded = !expanded },
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Surface(
                            shape = RoundedCornerShape(20.dp),
                            color = if (checkup.status == "completed") Color(0xFFD1FAE5)
                                    else Color(0xFFFEF3C7)
                        ) {
                            Text(
                                text = checkup.status.replaceFirstChar { it.uppercase() },
                                modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp),
                                style = MaterialTheme.typography.labelSmall.copy(
                                    color = if (checkup.status == "completed") Color(0xFF065F46)
                                            else Color(0xFF92400E),
                                    fontWeight = FontWeight.Medium
                                )
                            )
                        }
                        Spacer(Modifier.width(8.dp))
                        Text(
                            text = checkup.date,
                            style = MaterialTheme.typography.bodyMedium.copy(color = AmiyaGray)
                        )
                    }
                    Spacer(Modifier.height(4.dp))
                    Text(
                        text = checkup.doctorName,
                        style = MaterialTheme.typography.bodyLarge.copy(
                            fontWeight = FontWeight.SemiBold,
                            color = AmiyaDark
                        )
                    )
                    Text(
                        text = "Duration: ${checkup.duration}",
                        style = MaterialTheme.typography.bodySmall.copy(color = AmiyaGray)
                    )
                }
                Icon(
                    if (expanded) Icons.Default.KeyboardArrowUp else Icons.Default.KeyboardArrowDown,
                    contentDescription = null,
                    tint = AmiyaGray
                )
            }

            AnimatedVisibility(visible = expanded) {
                Column(modifier = Modifier.padding(top = 16.dp)) {
                    HorizontalDivider(color = Color(0xFFE5E7EB))
                    Spacer(Modifier.height(12.dp))

                    Text(
                        text = "Summary",
                        style = MaterialTheme.typography.bodyMedium.copy(
                            fontWeight = FontWeight.SemiBold,
                            color = AmiyaDark
                        )
                    )
                    Spacer(Modifier.height(4.dp))
                    Text(
                        text = checkup.summary,
                        style = MaterialTheme.typography.bodyMedium.copy(color = AmiyaGray)
                    )

                    if (checkup.nextSteps.isNotEmpty()) {
                        Spacer(Modifier.height(12.dp))
                        Text(
                            text = "Next Steps",
                            style = MaterialTheme.typography.bodyMedium.copy(
                                fontWeight = FontWeight.SemiBold,
                                color = AmiyaDark
                            )
                        )
                        checkup.nextSteps.forEach { step ->
                            Row(
                                modifier = Modifier.padding(top = 4.dp),
                                verticalAlignment = Alignment.Top
                            ) {
                                Text("• ", color = AmiyaPurple, fontWeight = FontWeight.Bold)
                                Text(
                                    text = step,
                                    style = MaterialTheme.typography.bodyMedium.copy(color = AmiyaGray)
                                )
                            }
                        }
                    }

                    Spacer(Modifier.height(12.dp))

                    TextButton(
                        onClick = { transcriptExpanded = !transcriptExpanded },
                        contentPadding = PaddingValues(0.dp)
                    ) {
                        Text(
                            text = if (transcriptExpanded) "Hide Transcript" else "View Transcript",
                            color = AmiyaPurple
                        )
                    }

                    AnimatedVisibility(visible = transcriptExpanded) {
                        Column {
                            checkup.transcript.forEach { entry ->
                                TranscriptBubble(entry)
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun TranscriptBubble(entry: TranscriptEntry) {
    val isDoctor = entry.speaker == "Doctor"
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        horizontalArrangement = if (isDoctor) Arrangement.Start else Arrangement.End
    ) {
        Column(horizontalAlignment = if (isDoctor) Alignment.Start else Alignment.End) {
            Text(
                text = entry.speaker,
                style = MaterialTheme.typography.labelSmall.copy(color = AmiyaGray),
                modifier = Modifier.padding(horizontal = 4.dp, vertical = 2.dp)
            )
            Surface(
                shape = RoundedCornerShape(12.dp),
                color = if (isDoctor) Color(0xFFF3F4F6) else Color(0xFFEDE9FE),
                modifier = Modifier.widthIn(max = 280.dp)
            ) {
                Text(
                    text = entry.text,
                    modifier = Modifier.padding(10.dp),
                    style = MaterialTheme.typography.bodyMedium.copy(color = AmiyaDark)
                )
            }
        }
    }
}
