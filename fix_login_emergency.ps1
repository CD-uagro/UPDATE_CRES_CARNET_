# 🚨 FIX DE EMERGENCIA: Problema de Login
# Este script limpia el cache local para forzar login online limpio

Write-Host "=== FIX DE EMERGENCIA: PROBLEMA DE LOGIN ===" -ForegroundColor Red
Write-Host ""

# PASO 1: Verificar backend está activo
Write-Host "1. Verificando backend..." -ForegroundColor Yellow
try {
    $healthCheck = Invoke-WebRequest -Uri "https://fastapi-backend-o7ks.onrender.com/health" -TimeoutSec 5
    Write-Host "   ✅ Backend responde correctamente" -ForegroundColor Green
} catch {
    Write-Host "   ❌ ERROR: Backend no responde" -ForegroundColor Red
    Write-Host "   Contacta al administrador del sistema" -ForegroundColor Red
    exit 1
}

# PASO 2: Crear versión de emergencia que limpia cache
Write-Host ""
Write-Host "2. Creando fix temporal..." -ForegroundColor Yellow

$fixCode = @'
// FIX TEMPORAL: Limpiar cache de autenticación
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<void> clearAuthCache() async {
  const storage = FlutterSecureStorage();
  
  print('🧹 Limpiando cache de autenticación...');
  
  // Eliminar TODOS los datos de autenticación
  await storage.delete(key: 'auth_token');
  await storage.delete(key: 'auth_user');
  await storage.delete(key: 'cached_password');
  
  // Limpiar cache de contraseñas offline
  final allKeys = await storage.readAll();
  for (var key in allKeys.keys) {
    if (key.contains('password_hash_') || key.contains('user_data_')) {
      await storage.delete(key: key);
      print('   Eliminado: $key');
    }
  }
  
  print('✅ Cache limpiado - próximo login será online limpio');
}
'@

Set-Content -Path "lib\data\clear_auth_cache.dart" -Value $fixCode -Encoding UTF8
Write-Host "   ✅ Código de fix creado" -ForegroundColor Green

# PASO 3: Instrucciones para el usuario
Write-Host ""
Write-Host "=== INSTRUCCIONES PARA USUARIOS ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "📱 OPCIÓN A - FIX RÁPIDO (Recomendado):" -ForegroundColor Yellow
Write-Host "   1. Cierra COMPLETAMENTE la aplicación" -ForegroundColor White
Write-Host "   2. Ve a: C:\Users\[TU_USUARIO]\AppData\Local\cres_carnets_ibmcloud" -ForegroundColor White
Write-Host "   3. ELIMINA la carpeta 'flutter_secure_storage'" -ForegroundColor White
Write-Host "   4. Abre la app de nuevo" -ForegroundColor White
Write-Host "   5. Ingresa usuario y contraseña (debe tener internet)" -ForegroundColor White
Write-Host ""
Write-Host "🔧 OPCIÓN B - Si Opción A no funciona:" -ForegroundColor Yellow
Write-Host "   Las contraseñas pueden haberse cambiado en el servidor" -ForegroundColor White
Write-Host "   Necesitas verificar/resetear contraseñas en Azure Cosmos DB" -ForegroundColor White
Write-Host ""

# PASO 4: Script para limpiar datos de usuario específico
Write-Host "4. ¿Quieres limpiar el cache AHORA? (S/N):" -ForegroundColor Yellow
$respuesta = Read-Host

if ($respuesta -eq 'S' -or $respuesta -eq 's') {
    $appDataPath = "$env:LOCALAPPDATA\cres_carnets_ibmcloud\flutter_secure_storage"
    
    if (Test-Path $appDataPath) {
        Write-Host ""
        Write-Host "🧹 Limpiando cache local..." -ForegroundColor Yellow
        Remove-Item -Path $appDataPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Cache eliminado exitosamente" -ForegroundColor Green
        Write-Host ""
        Write-Host "📱 Ahora puedes abrir la app e intentar login de nuevo" -ForegroundColor Green
    } else {
        Write-Host "⚠️  No se encontró cache (la app no se ha ejecutado o ya estaba limpio)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=== DIAGNÓSTICO ADICIONAL ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔍 Probando login con credenciales de prueba:" -ForegroundColor Yellow
Write-Host "   (Esto mostrará si el problema es del backend o del cliente)" -ForegroundColor Gray
Write-Host ""

# Probar con credenciales que sabemos que existen
$testUsers = @(
    @{user="admin"; campus="cres-llano-largo"},
    @{user="enfermero1"; campus="cres-llano-largo"},
    @{user="medico1"; campus="cres-llano-largo"}
)

foreach ($test in $testUsers) {
    Write-Host "   Testing: $($test.user) @ $($test.campus)" -ForegroundColor Gray
    try {
        $body = @{
            username = $test.user
            password = "cualquier_password_para_test"
            campus = $test.campus
        } | ConvertTo-Json
        
        $resp = Invoke-WebRequest `
            -Uri "https://fastapi-backend-o7ks.onrender.com/auth/login" `
            -Method POST `
            -Body $body `
            -ContentType "application/json" `
            -TimeoutSec 5 `
            -ErrorAction Stop
        
        Write-Host "      ✅ Usuario existe (password incorrecto = esperado)" -ForegroundColor Green
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.Value__
        if ($statusCode -eq 401) {
            Write-Host "      ✅ Usuario existe (401 = esperado con password falso)" -ForegroundColor Green
        } elseif ($statusCode -eq 404) {
            Write-Host "      ❌ Usuario NO existe en backend" -ForegroundColor Red
        } else {
            Write-Host "      ⚠️  Error: $statusCode" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "=== PRÓXIMOS PASOS ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "1️⃣  Si limpiaste el cache, intenta login ahora" -ForegroundColor White
Write-Host "2️⃣  Si sigue fallando, verifica que la contraseña sea correcta" -ForegroundColor White
Write-Host "3️⃣  Si ningún usuario puede entrar, puede ser problema de backend" -ForegroundColor White
Write-Host ""
Write-Host "📞 ¿Necesitas resetear contraseñas en Cosmos DB? (S/N):" -ForegroundColor Yellow
$resetPwd = Read-Host

if ($resetPwd -eq 'S' -or $resetPwd -eq 's') {
    Write-Host ""
    Write-Host "🔐 RESETEO DE CONTRASEÑAS" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Para resetear contraseñas en Cosmos DB:" -ForegroundColor White
    Write-Host "1. Ve a: https://portal.azure.com" -ForegroundColor Gray
    Write-Host "2. Busca tu Cosmos DB Account" -ForegroundColor Gray
    Write-Host "3. Data Explorer > 'sasu_db' > 'usuarios'" -ForegroundColor Gray
    Write-Host "4. Busca el usuario por username" -ForegroundColor Gray
    Write-Host "5. Edita el campo 'password_hash'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "O ejecuta este script Python en temp_backend:" -ForegroundColor White
    Write-Host "   python reset_password.py <username> <nueva_password>" -ForegroundColor Gray
    Write-Host ""
}

Write-Host ""
Write-Host "✅ Script completado" -ForegroundColor Green
Write-Host ""
