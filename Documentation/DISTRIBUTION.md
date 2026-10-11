# Veltrix Security - Guía de Distribución

**Última actualización:** 2026-10-11  
**Status:** Fase 8 - Listo para firma

---

## 1. Configuración de Firma

### Estado Actual
```
Bundle Identifier:     com.cynaxia.veltrixsecurity
Product Name:          VeltrixSecurity
Code Signing Style:    Automatic
Hardened Runtime:      ✅ Enabled
Team ID:               (Requeried Developer ID)
```

### Verificar Firma
```bash
# Verificar que el proyecto está firmado
xcodebuild build -scheme VeltrixSecurity -configuration Release

# Verificar la firma del binario resultante
codesign -v /path/to/VeltrixSecurity.app
```

---

## 2. Hardened Runtime

### Status
✅ Habilitado en project.yml

### Entitlements Requeridos
```xml
<!-- Current: None (app runs in default sandbox context) -->
<!-- Future: Add if distributing via Mac App Store -->
```

### Verificación
```bash
codesign -d --entitlements :- /path/to/VeltrixSecurity.app
```

---

## 3. Decisión: Developer ID vs Mac App Store

### Opción A: Developer ID (Recomendado)
✅ **Pros:**
- Libertad funcional completa
- No sujeto a restricciones de App Store
- Control total sobre distribución
- Distribución directa

❌ **Contras:**
- Requiere certificado Developer ID
- Notarización obligatoria
- Responsabilidad de soporte

### Opción B: Mac App Store
✅ **Pros:**
- Distribución centralizada
- Confianza del usuario (firma de Apple)
- Actualizaciones automáticas
- Marketing de App Store

❌ **Contras:**
- Revisión de Apple (1-3 días)
- Requiere Sandbox
- Restricciones de funcionalidad
- Comisión de Apple (30%)

**Decisión Recomendada:** Developer ID (Mayor control, funcionalidad completa)

---

## 4. Proceso de Firma con Developer ID

### 4.1 Obtener Certificado
```bash
# En Xcode: Preferences > Accounts > Signing Certificates
# O desde: https://developer.apple.com/account/

# Requerido:
# - Apple Developer Account ($99/año)
# - Developer ID Application Certificate
# - Developer ID Installer Certificate (para PKG)
```

### 4.2 Configurar en Xcode
```
Targets > VeltrixSecurity > Signing & Capabilities
├─ Team: Select your team
├─ Signing Certificate: Developer ID Application
└─ Bundle Identifier: com.cynaxia.veltrixsecurity
```

### 4.3 Construir y Firmar
```bash
# Build con release configuration
xcodebuild archive \
  -scheme VeltrixSecurity \
  -configuration Release \
  -archivePath ./VeltrixSecurity.xcarchive \
  -signingStyle automatic

# Exportar app
xcodebuild -exportArchive \
  -archivePath ./VeltrixSecurity.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath ./build/
```

---

## 5. Notarización

### 5.1 Preparar App para Notarización
```bash
# El app debe estar firmado antes de notarizar
codesign -v /path/to/VeltrixSecurity.app

# Crear ticket de notarización
xcrun notarytool submit /path/to/VeltrixSecurity.app \
  --apple-id your-apple-id@example.com \
  --team-id YOUR_TEAM_ID \
  --password YOUR_APP_SPECIFIC_PASSWORD
```

### 5.2 Esperar Aprobación
- Tiempo típico: 5-30 minutos
- Apple verifica: malware, contenido prohibido, entitlements válidos

### 5.3 Grapar Ticket
```bash
xcrun stapler staple /path/to/VeltrixSecurity.app
```

---

## 6. Crear DMG de Distribución

### Script: create_dmg.sh
```bash
#!/bin/bash
set -e

APP_PATH="./build/VeltrixSecurity.app"
DMG_NAME="VeltrixSecurity-1.0.0.dmg"
TEMP_DMG="temp-veltrix.dmg"

# Crear DMG temporal
hdiutil create -volname "Veltrix Security" \
  -srcfolder "$APP_PATH" \
  -ov -format UDZO \
  -imagekey zlib-level=9 \
  "$TEMP_DMG"

# Adjuntar archivo de licencia (opcional)
# hdiutil attach temp-veltrix.dmg
# cp LICENSE.txt /Volumes/Veltrix\ Security/
# hdiutil detach /Volumes/Veltrix\ Security

# Renombrar a final
mv "$TEMP_DMG" "$DMG_NAME"

# Verificar
echo "✅ DMG created: $DMG_NAME"
ls -lh "$DMG_NAME"

# Firmar DMG
codesign --sign "Developer ID Application" "$DMG_NAME"
echo "✅ DMG signed"
```

### Uso
```bash
chmod +x create_dmg.sh
./create_dmg.sh
```

---

## 7. Testing Final

### 7.1 Verificar en /Applications
```bash
# Copiar app a /Applications
cp -r ./build/VeltrixSecurity.app /Applications/

# Lanzar desde Finder o terminal
open /Applications/VeltrixSecurity.app

# Verificar en Activity Monitor
# Lanzar desde Launchpad (requiere actualizar índice de Spotlight)
```

### 7.2 Verificación de Seguridad
```bash
# Verificar que macOS permite ejecutar (Gatekeeper)
spctl -a -v /Applications/VeltrixSecurity.app

# Debería mostrar:
# /Applications/VeltrixSecurity.app: accepted
# source=Developer ID
```

### 7.3 Test Cases
- [ ] App lanza sin errores
- [ ] Todas las vistas carguen
- [ ] Limpieza programada se puede activar
- [ ] Tests siguen pasando
- [ ] No hay advertencias de seguridad en Console.app
- [ ] Permisos se solicitan adecuadamente

---

## 8. Distribución Directa

### Opción 1: Sitio Web
```
1. Subir VeltrixSecurity-1.0.0.dmg a sitio
2. Incluir: versión, SHA256, notas de lanzamiento
3. Enlace de descarga
```

### Opción 2: GitHub Releases
```bash
gh release create v1.0.0 VeltrixSecurity-1.0.0.dmg \
  --title "Veltrix Security 1.0.0" \
  --notes "Release notes here"
```

### Opción 3: Aplicación Auto-Update
```
Integrar: Sparkle framework
- Vigilar releases en GitHub/servidor
- Descargar y instalar automáticamente
- Notificar al usuario
```

---

## 9. Checklist Pre-Lanzamiento

- [ ] Bundle identifier correcto: com.cynaxia.veltrixsecurity
- [ ] Product name: VeltrixSecurity
- [ ] Version number actualizada
- [ ] Build number actualizado
- [ ] Todos los tests pasan
- [ ] Sin warnings de compilación
- [ ] Código signado correctamente
- [ ] Notarización completada ✓
- [ ] DMG probado en macOS limpio
- [ ] Gatekeeper acepta app
- [ ] Privacidad/Seguridad auditada
- [ ] Notas de lanzamiento preparadas

---

## 10. Después del Lanzamiento

### Monitoreo
- Recolectar logs de errores
- Escuchar feedback de usuarios
- Vigilar uso de CPU/memoria
- Verificar actualizaciones automáticas

### Actualizaciones Futuras
- Mantener versionado semántico
- Firmar y notarizar cada versión
- Publicar notas de lanzamiento
- Comunicar cambios a usuarios

---

**Status:** Fase 8 completa  
**Siguiente:** Empaquetado DMG final
