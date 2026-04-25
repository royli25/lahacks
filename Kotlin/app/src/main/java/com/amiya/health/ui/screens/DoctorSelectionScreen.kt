package com.amiya.health.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Person
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
import com.amiya.health.data.models.DOCTOR_PROFILES
import com.amiya.health.data.models.DoctorProfile
import com.amiya.health.ui.theme.AmiyaDark
import com.amiya.health.ui.theme.AmiyaGray
import com.amiya.health.ui.theme.AmiyaPurple

@Composable
fun DoctorSelectionScreen(
    patientName: String,
    onDoctorSelected: (doctorId: String, doctorName: String) -> Unit,
    onBack: () -> Unit
) {
    var selectedId by remember { mutableStateOf<String?>(null) }

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
                .padding(24.dp)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                IconButton(onClick = onBack) {
                    Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                }
                Spacer(Modifier.width(8.dp))
                Text(
                    text = "Choose Your Doctor",
                    style = MaterialTheme.typography.headlineMedium.copy(color = AmiyaDark)
                )
            }

            Spacer(Modifier.height(4.dp))

            Text(
                text = "Hi $patientName! Select a doctor for your checkup",
                style = MaterialTheme.typography.bodyMedium.copy(color = AmiyaGray),
                modifier = Modifier.padding(start = 48.dp)
            )

            Spacer(Modifier.height(24.dp))

            LazyVerticalGrid(
                columns = GridCells.Fixed(1),
                verticalArrangement = Arrangement.spacedBy(16.dp),
                modifier = Modifier.weight(1f)
            ) {
                items(DOCTOR_PROFILES) { doctor ->
                    DoctorCard(
                        doctor = doctor,
                        isSelected = selectedId == doctor.id,
                        onClick = { selectedId = doctor.id }
                    )
                }
            }

            Spacer(Modifier.height(24.dp))

            Button(
                onClick = {
                    val selected = DOCTOR_PROFILES.find { it.id == selectedId } ?: return@Button
                    onDoctorSelected(selected.id, selected.agentName)
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(containerColor = AmiyaPurple),
                enabled = selectedId != null
            ) {
                Text(
                    text = "Continue with Selected Doctor",
                    color = AmiyaDark,
                    fontWeight = FontWeight.SemiBold
                )
            }
        }
    }
}

@Composable
private fun DoctorCard(
    doctor: DoctorProfile,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .then(
                if (isSelected) Modifier.border(2.dp, AmiyaPurple, RoundedCornerShape(16.dp))
                else Modifier
            ),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (isSelected) Color(0xFFF5F0FF) else Color.White
        ),
        elevation = CardDefaults.cardElevation(if (isSelected) 4.dp else 2.dp)
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(64.dp)
                    .clip(CircleShape)
                    .background(if (isSelected) AmiyaPurple else Color(0xFFE5E7EB)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    Icons.Default.Person,
                    contentDescription = null,
                    modifier = Modifier.size(36.dp),
                    tint = if (isSelected) AmiyaDark else AmiyaGray
                )
            }

            Spacer(Modifier.width(16.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = doctor.displayName,
                    style = MaterialTheme.typography.bodyLarge.copy(
                        fontWeight = FontWeight.SemiBold,
                        color = AmiyaDark
                    )
                )
                Text(
                    text = doctor.specialty,
                    style = MaterialTheme.typography.bodyMedium.copy(color = AmiyaGray),
                    modifier = Modifier.padding(top = 4.dp)
                )
            }

            if (isSelected) {
                Box(
                    modifier = Modifier
                        .size(24.dp)
                        .clip(CircleShape)
                        .background(AmiyaPurple),
                    contentAlignment = Alignment.Center
                ) {
                    Text("✓", color = AmiyaDark, style = MaterialTheme.typography.labelSmall)
                }
            }
        }
    }
}
