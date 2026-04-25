package com.amiya.health.ui.screens

import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.viewmodel.compose.viewModel
import com.amiya.health.ui.theme.AmiyaDark
import com.amiya.health.ui.theme.AmiyaGray
import com.amiya.health.ui.theme.AmiyaPurple
import com.amiya.health.viewmodel.CheckupViewModel
import com.amiya.health.viewmodel.CheckupViewModelFactory
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.rememberMultiplePermissionsState

@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun CheckupScreen(
    uid: String,
    patientName: String,
    doctorId: String,
    doctorName: String,
    onCallEnded: () -> Unit
) {
    val context = LocalContext.current
    val viewModel: CheckupViewModel = viewModel(
        factory = CheckupViewModelFactory(context, uid, patientName, doctorId, doctorName)
    )

    val permissions = rememberMultiplePermissionsState(
        permissions = listOf(
            android.Manifest.permission.RECORD_AUDIO,
            android.Manifest.permission.CAMERA
        )
    )

    val uiState by viewModel.uiState.collectAsState()
    val transcript by viewModel.transcript.collectAsState()
    val listState = rememberLazyListState()

    LaunchedEffect(transcript.size) {
        if (transcript.isNotEmpty()) {
            listState.animateScrollToItem(transcript.size - 1)
        }
    }

    LaunchedEffect(Unit) {
        if (!permissions.allPermissionsGranted) {
            permissions.launchMultiplePermissionRequest()
        }
    }

    if (!permissions.allPermissionsGranted) {
        PermissionsNeededScreen(onRequest = { permissions.launchMultiplePermissionRequest() })
        return
    }

    Box(modifier = Modifier.fillMaxSize().background(Color.Black)) {

        // HeyGen WebView avatar fills the screen
        HeyGenWebView(
            sessionToken = uiState.heygenToken,
            sessionData = uiState.heygenSession,
            modifier = Modifier.fillMaxSize()
        )

        // Title overlay
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .align(Alignment.TopCenter)
                .background(Color.Black.copy(alpha = 0.4f))
                .padding(16.dp)
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
                Text(
                    text = patientName,
                    style = MaterialTheme.typography.bodyLarge.copy(
                        color = Color.White,
                        fontWeight = FontWeight.SemiBold
                    )
                )
                Text(
                    text = "with $doctorName",
                    style = MaterialTheme.typography.bodySmall.copy(color = Color.White.copy(alpha = 0.8f))
                )
            }
        }

        // Transcript panel (right side)
        AnimatedVisibility(
            visible = transcript.isNotEmpty(),
            modifier = Modifier
                .fillMaxHeight()
                .width(220.dp)
                .align(Alignment.CenterEnd)
        ) {
            Box(
                modifier = Modifier
                    .fillMaxHeight()
                    .background(Color.Black.copy(alpha = 0.6f))
                    .padding(8.dp)
            ) {
                LazyColumn(
                    state = listState,
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                    contentPadding = PaddingValues(top = 60.dp, bottom = 120.dp)
                ) {
                    items(transcript) { entry ->
                        val isDoctor = entry.speaker == "Doctor"
                        Column(
                            horizontalAlignment = if (isDoctor) Alignment.Start else Alignment.End,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text(
                                text = entry.speaker,
                                style = MaterialTheme.typography.labelSmall.copy(
                                    color = Color.White.copy(alpha = 0.6f)
                                ),
                                modifier = Modifier.padding(horizontal = 4.dp, vertical = 2.dp)
                            )
                            Surface(
                                shape = RoundedCornerShape(10.dp),
                                color = if (isDoctor) Color.White.copy(alpha = 0.15f)
                                        else AmiyaPurple.copy(alpha = 0.4f)
                            ) {
                                Text(
                                    text = entry.text,
                                    modifier = Modifier.padding(8.dp),
                                    style = MaterialTheme.typography.bodySmall.copy(color = Color.White),
                                    fontSize = 12.sp
                                )
                            }
                        }
                    }
                }
            }
        }

        // Status indicator
        Box(
            modifier = Modifier
                .align(Alignment.TopStart)
                .padding(16.dp)
                .padding(top = 56.dp)
        ) {
            StatusPill(
                isRecording = uiState.isRecording,
                isWhisperActive = uiState.isWhisperEnabled
            )
        }

        // Loading overlay
        if (uiState.isLoading) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.7f)),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    CircularProgressIndicator(color = AmiyaPurple)
                    Spacer(Modifier.height(16.dp))
                    Text(
                        text = uiState.loadingMessage,
                        color = Color.White,
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }
        }

        // Control bar
        Row(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = 32.dp)
                .clip(RoundedCornerShape(32.dp))
                .background(Color.Black.copy(alpha = 0.6f))
                .padding(horizontal = 24.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.spacedBy(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            ControlButton(
                icon = if (uiState.isMuted) Icons.Default.MicOff else Icons.Default.Mic,
                label = if (uiState.isMuted) "Unmute" else "Mute",
                tint = if (uiState.isMuted) Color(0xFFEF4444) else Color.White,
                onClick = { viewModel.toggleMute() }
            )

            ControlButton(
                icon = Icons.Default.RecordVoiceOver,
                label = "Transcribe",
                tint = if (uiState.isWhisperEnabled) AmiyaPurple else Color.White,
                onClick = { viewModel.toggleWhisper() }
            )

            // End call button
            Box(
                modifier = Modifier
                    .size(56.dp)
                    .clip(CircleShape)
                    .background(Color(0xFFEF4444)),
                contentAlignment = Alignment.Center
            ) {
                IconButton(
                    onClick = {
                        viewModel.endCall()
                        onCallEnded()
                    }
                ) {
                    Icon(
                        Icons.Default.CallEnd,
                        contentDescription = "End Call",
                        tint = Color.White,
                        modifier = Modifier.size(28.dp)
                    )
                }
            }

            ControlButton(
                icon = Icons.Default.VideocamOff,
                label = "Camera",
                tint = Color.White,
                onClick = { viewModel.toggleCamera() }
            )

            ControlButton(
                icon = Icons.Default.Info,
                label = "Summary",
                tint = Color.White,
                onClick = { viewModel.requestSummary() }
            )
        }
    }
}

@Composable
private fun ControlButton(
    icon: ImageVector,
    label: String,
    tint: Color,
    onClick: () -> Unit
) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        IconButton(
            onClick = onClick,
            modifier = Modifier
                .size(44.dp)
                .clip(CircleShape)
                .background(Color.White.copy(alpha = 0.15f))
        ) {
            Icon(icon, contentDescription = label, tint = tint, modifier = Modifier.size(22.dp))
        }
        Text(
            text = label,
            color = Color.White.copy(alpha = 0.7f),
            fontSize = 10.sp
        )
    }
}

@Composable
private fun StatusPill(isRecording: Boolean, isWhisperActive: Boolean) {
    if (!isRecording && !isWhisperActive) return

    Surface(
        shape = RoundedCornerShape(20.dp),
        color = Color.Black.copy(alpha = 0.6f)
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(8.dp)
                    .clip(CircleShape)
                    .background(if (isRecording) Color(0xFFEF4444) else AmiyaPurple)
            )
            Text(
                text = if (isRecording) "Recording" else "Whisper Ready",
                color = Color.White,
                fontSize = 12.sp
            )
        }
    }
}

@Composable
private fun PermissionsNeededScreen(onRequest: () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Icon(
                Icons.Default.MicOff,
                contentDescription = null,
                tint = Color.White,
                modifier = Modifier.size(64.dp)
            )
            Spacer(Modifier.height(16.dp))
            Text(
                text = "Microphone & Camera Access Required",
                color = Color.White,
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.SemiBold
            )
            Spacer(Modifier.height(8.dp))
            Text(
                text = "Please grant permissions to start your checkup",
                color = Color.White.copy(alpha = 0.7f),
                style = MaterialTheme.typography.bodyMedium
            )
            Spacer(Modifier.height(24.dp))
            Button(
                onClick = onRequest,
                colors = ButtonDefaults.buttonColors(containerColor = AmiyaPurple)
            ) {
                Text("Grant Permissions", color = AmiyaDark)
            }
        }
    }
}

@Composable
private fun HeyGenWebView(
    sessionToken: String?,
    sessionData: String?,
    modifier: Modifier = Modifier
) {
    if (sessionToken == null) {
        Box(modifier = modifier.background(Color(0xFF1A1A2E)), contentAlignment = Alignment.Center) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                CircularProgressIndicator(color = AmiyaPurple)
                Spacer(Modifier.height(12.dp))
                Text("Connecting to doctor...", color = Color.White)
            }
        }
        return
    }

    AndroidView(
        modifier = modifier,
        factory = { ctx ->
            WebView(ctx).apply {
                settings.apply {
                    javaScriptEnabled = true
                    domStorageEnabled = true
                    mediaPlaybackRequiresUserGesture = false
                    mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
                    allowFileAccess = true
                    cacheMode = WebSettings.LOAD_NO_CACHE
                }
                webViewClient = WebViewClient()
                // Load the HeyGen streaming avatar HTML
                loadDataWithBaseURL(
                    "https://api.heygen.com",
                    buildHeyGenHtml(sessionToken, sessionData ?: ""),
                    "text/html",
                    "UTF-8",
                    null
                )
            }
        },
        update = { webView ->
            // Re-load if token changes
        }
    )
}

private fun buildHeyGenHtml(token: String, sessionJson: String): String = """
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { background: #0D1117; width: 100vw; height: 100vh; display: flex; align-items: center; justify-content: center; }
    video { width: 100%; height: 100%; object-fit: cover; }
    #status { position: absolute; top: 10px; left: 10px; color: white; font-family: sans-serif; font-size: 12px; background: rgba(0,0,0,0.5); padding: 4px 8px; border-radius: 4px; }
  </style>
</head>
<body>
  <video id="avatarVideo" autoplay playsinline></video>
  <div id="status">Initializing...</div>
  <script>
    const TOKEN = "${token}";
    const STATUS = document.getElementById('status');

    async function initAvatar() {
      try {
        STATUS.textContent = 'Loading HeyGen SDK...';
        const script = document.createElement('script');
        script.src = 'https://cdn.jsdelivr.net/npm/@heygen/streaming-avatar@latest/dist/index.umd.js';
        script.onload = async () => {
          STATUS.textContent = 'Connecting...';
          const avatar = new HeyGenStreamingAvatar({ token: TOKEN });
          const session = await avatar.createStartAvatar({
            quality: 'medium',
            avatarName: 'default',
            voice: { rate: 1.0, emotion: 'Friendly' }
          });
          const videoEl = document.getElementById('avatarVideo');
          if (session.stream) videoEl.srcObject = session.stream;
          STATUS.textContent = 'Connected';
          window._avatar = avatar;
        };
        document.head.appendChild(script);
      } catch(e) {
        STATUS.textContent = 'Error: ' + e.message;
      }
    }
    initAvatar();
  </script>
</body>
</html>
""".trimIndent()
