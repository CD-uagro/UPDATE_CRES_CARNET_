# 🚨 INSTRUCCIONES DE INSTALACIÓN URGENTE
# FIX v2.4.34 - Problema de Login en Windows

## ⚠️ PROBLEMA
**No puedes entrar a la aplicación** - Las contraseñas son rechazadas.

## ✅ SOLUCIÓN
Instalar manualmente la versión 2.4.34 que corrige el problema.

---

## 📋 PASOS DE INSTALACIÓN (5 minutos)

### **1. DESCARGAR EL FIX**
   - Archivo: `CRES_Carnets_Windows_v2.4.34_fix_login.zip`
   - Tamaño: 15.87 MB
   - Ubicación: [El administrador te lo enviará por WhatsApp/USB/Email]

### **2. LOCALIZAR TU INSTALACIÓN ACTUAL**
   La app generalmente está en una de estas carpetas:
   
   **Opción A** (más común):
   ```
   C:\CRES_Carnets\
   ```
   
   **Opción B**:
   ```
   C:\Program Files\CRES_Carnets\
   ```
   
   **Opción C** (escritorio):
   ```
   C:\Users\[TU_USUARIO]\Desktop\CRES_Carnets\
   ```
   
   💡 **¿No la encuentras?** 
   - Click derecho en el icono de la app
   - "Abrir ubicación del archivo"
   - Te llevará a la carpeta correcta

### **3. RESPALDAR (Opcional pero Recomendado)**
   ```
   1. Copia la carpeta actual completa
   2. Pégala en otro lugar como respaldo
   3. Nómbrala: CRES_Carnets_RESPALDO
   ```

### **4. CERRAR LA APLICACIÓN**
   ```
   ⚠️ MUY IMPORTANTE:
   - Cierra COMPLETAMENTE la aplicación
   - Verifica en el Administrador de Tareas que no esté corriendo
   - Presiona Ctrl+Shift+Esc
   - Busca "cres_carnets_ibmcloud.exe"
   - Si aparece, click derecho → Finalizar tarea
   ```

### **5. EXTRAER Y REEMPLAZAR**
   ```
   1. Click derecho en CRES_Carnets_Windows_v2.4.34_fix_login.zip
   2. "Extraer aquí" o "Extract here"
   3. Selecciona TODOS los archivos extraídos
   4. Copia (Ctrl+C)
   5. Ve a la carpeta de instalación (del paso 2)
   6. Pega (Ctrl+V)
   7. Cuando pregunte si reemplazar archivos → "Sí a todo"
   ```

### **6. LIMPIAR CACHE (Importante)**
   ```
   1. Presiona Win+R
   2. Escribe: %localappdata%
   3. Busca la carpeta: cres_carnets_ibmcloud
   4. ELIMINA toda esa carpeta
   5. (Se creará nueva al abrir la app)
   ```

### **7. ABRIR LA APLICACIÓN**
   ```
   1. Abre la aplicación normalmente
   2. ESPERA 10-15 segundos en la pantalla de login
      (el servidor puede estar "despertando")
   3. Ingresa tu usuario y contraseña
   4. ✅ Deberías poder entrar ahora
   ```

---

## 🎯 ¿QUÉ SE CORRIGIÓ?

El problema era que la app esperaba solo **3 segundos** para que el servidor respondiera.
Cuando el servidor está "dormido", tarda **8-10 segundos** en despertar.

**Cambios en v2.4.34:**
- ✅ Ahora espera hasta **15 segundos** para login
- ✅ Ahora espera hasta **10 segundos** para verificar internet
- ✅ Muestra mensaje informativo durante la espera

---

## ❓ PREGUNTAS FRECUENTES

### ❓ "¿Por qué no puedo entrar?"
El timeout era muy corto. La nueva versión espera más tiempo.

### ❓ "¿La app móvil tiene el mismo problema?"
No. Solo afecta a Windows porque el servidor a veces está dormido.

### ❓ "¿Necesito internet?"
Sí, para el PRIMER login. Después puedes trabajar offline.

### ❓ "¿Perderé mis datos?"
No. Los datos locales NO se borran con esta actualización.

### ❓ "¿Qué hago si sigue sin funcionar?"
1. Verifica que tengas internet
2. Espera 15-20 segundos en el login
3. Si aún falla, contacta al administrador

### ❓ "¿Cómo sé si instalé la versión correcta?"
Después de entrar:
- Ve al Dashboard
- Abajo del logo SASU verás: **"v2.4.34 (34)"**

---

## 📞 SOPORTE

Si después de seguir estos pasos NO puedes entrar:

1. **Toma captura de pantalla** del error
2. **Anota** qué paso exactamente hiciste
3. **Contacta** al administrador del sistema
4. **Verifica** que tienes internet activo

---

## 📝 NOTAS TÉCNICAS

**Versión:** 2.4.34 (build 34)
**Fecha:** 26 de noviembre de 2025
**Tamaño:** 15.87 MB
**SHA256:** 63FA7ECC6D42F3BE89A2FA7DC4910EDDC9E4F7D9E503C54F87075081A4215DA50

**Archivos principales que cambiaron:**
- `data/flutter_assets/kernel_blob.bin` (lógica de autenticación)
- `cres_carnets_ibmcloud.exe` (ejecutable principal)

---

## ✅ VERIFICACIÓN POST-INSTALACIÓN

Después de instalar, verifica:
- [ ] La app abre correctamente
- [ ] Puedes ver la pantalla de login
- [ ] Aparece el dropdown de campus
- [ ] Al ingresar usuario/password, espera ~10 segundos
- [ ] Puedes entrar exitosamente
- [ ] Ves "v2.4.34 (34)" en el dashboard

---

**¡Listo!** Con esto deberías poder entrar nuevamente. 🎉
