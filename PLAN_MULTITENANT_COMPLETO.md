# 🚀 PLAN COMPLETO: CONVERTIR SASU EN PRODUCTO MULTI-TENANT

**Fecha**: Noviembre 2025
**Versión Base**: v2.4.33 (estable)
**Objetivo**: Sistema SaaS vendible a múltiples escuelas

---

## 📋 ÍNDICE
1. [Arquitectura y Decisiones Técnicas](#arquitectura)
2. [Infraestructura Azure (Costos y Configuración)](#infraestructura)
3. [Plan de Implementación por Fases](#fases)
4. [Checklist de Tareas](#checklist)
5. [Estimación de Tiempos y Costos](#estimacion)
6. [Riesgos y Mitigaciones](#riesgos)

---

## 🏗️ ARQUITECTURA Y DECISIONES TÉCNICAS <a name="arquitectura"></a>

### **Decisión 1: ¿Una Base de Datos o Varias?**

#### **Opción A: Una Sola Base de Datos (RECOMENDADO) ⭐**

**Arquitectura:**
```
Azure Cosmos DB (UNA SOLA)
├── Container: carnets
│   ├── Partition Key: /tenant_id
│   ├── CRES Llano Largo (tenant_id: "cres_llano_largo")
│   │   ├── carnet:uuid1 → Juan Pérez
│   │   └── carnet:uuid2 → María López
│   ├── Primaria Benito Juárez (tenant_id: "primaria_benito")
│   │   ├── carnet:uuid3 → Ana Rodríguez
│   │   └── carnet:uuid4 → Luis Hernández
│   └── Secundaria Hidalgo (tenant_id: "secundaria_hidalgo")
│       ├── carnet:uuid5 → Carlos Díaz
│       └── carnet:uuid6 → Laura Ramírez
│
├── Container: notas (mismo esquema con tenant_id)
├── Container: citas (mismo esquema con tenant_id)
├── Container: usuarios (mismo esquema con tenant_id)
└── Container: tenants (info de cada escuela)
```

**✅ VENTAJAS:**
- Costo MUCHO más bajo (un solo DB)
- Más fácil de mantener
- Respaldos centralizados
- Escalable hasta 1000+ escuelas sin problemas
- Cosmos DB cobra por RU/s, no por base de datos

**❌ DESVENTAJAS:**
- Debes programar bien los filtros (siempre incluir tenant_id)
- Si hay bug, afecta a todas las escuelas
- Necesitas auditoría fuerte para evitar fugas de datos

**💰 COSTO MENSUAL:**
- Cosmos DB: $24 USD/mes base (400 RU/s)
- Por cada 10 escuelas: +$10 USD/mes aprox
- 50 escuelas: ~$75-100 USD/mes

**📊 ESCALABILIDAD:**
- Hasta 100 escuelas: Sin cambios
- 100-500 escuelas: Aumentar RU/s ($50-100/mes)
- 500+ escuelas: Considerar sharding avanzado

---

#### **Opción B: Base de Datos por Escuela**

**Arquitectura:**
```
Azure Cosmos DB - CRES Llano Largo
├── Container: carnets
├── Container: notas
└── Container: citas

Azure Cosmos DB - Primaria Benito Juárez
├── Container: carnets
├── Container: notas
└── Container: citas

Azure Cosmos DB - Secundaria Hidalgo
├── Container: carnets
├── Container: notas
└── Container: citas
```

**✅ VENTAJAS:**
- Aislamiento total de datos (más seguro)
- Falla en una DB no afecta otras
- Fácil de respaldar por escuela

**❌ DESVENTAJAS:**
- CARO: $24 USD/mes × número de escuelas
- 50 escuelas = $1,200 USD/mes en bases de datos
- Difícil de mantener (50 DBs diferentes)
- Actualizaciones complicadas

**💰 COSTO MENSUAL:**
- 10 escuelas: $240 USD/mes
- 50 escuelas: $1,200 USD/mes
- 100 escuelas: $2,400 USD/mes

**❌ NO RECOMENDADO** salvo que vendas a gobiernos/empresas grandes que EXIJAN base de datos dedicada.

---

### **Decisión 2: ¿Dónde Guardar Logos y Archivos?**

**Azure Blob Storage (RECOMENDADO)**

```
Azure Blob Storage
├── Container: tenant-logos
│   ├── cres_llano_largo/logo.png
│   ├── primaria_benito/logo.png
│   └── secundaria_hidalgo/logo.png
│
└── Container: student-documents
    ├── cres_llano_largo/
    │   ├── matricula_001/certificado_medico.pdf
    │   └── matricula_002/radiografia.jpg
    └── primaria_benito/
        └── matricula_101/vacuna.pdf
```

**💰 COSTO:**
- $0.02 USD por GB/mes
- 100 logos (5MB c/u) = 500MB = $0.01/mes
- 10,000 documentos (1MB c/u) = 10GB = $0.20/mes
- **Total: ~$5-10 USD/mes** (incluso con miles de archivos)

---

### **Decisión 3: Backend - ¿Un Server o Varios?**

**UN SOLO BACKEND (Render.com o Azure App Service)**

```
Backend FastAPI (render.com)
├── Endpoint: /carnet/ (filtra por tenant_id automático)
├── Endpoint: /notas/ (filtra por tenant_id automático)
├── Endpoint: /tenant/config/{tenant_id}
└── Middleware: Inyecta tenant_id desde JWT token
```

**💰 COSTO:**
- Render.com: $7 USD/mes (plan actual)
- Azure App Service: $13 USD/mes (Basic)
- Para 100+ escuelas: mismo costo (escala automático)

---

## 💎 INFRAESTRUCTURA AZURE - CONFIGURACIÓN Y COSTOS <a name="infraestructura"></a>

### **Configuración Actual (CRES Llano Largo solamente)**

```
├── Azure Cosmos DB: "sasu_db"
│   ├── Container: carnets
│   ├── Container: notas
│   ├── Container: citas
│   ├── Container: promociones_salud
│   ├── Container: tarjeta_vacunacion
│   ├── Container: usuarios
│   └── Container: auditoria
│
└── Render.com
    └── Backend FastAPI (main.py)

💰 COSTO ACTUAL: ~$31 USD/mes
   - Cosmos DB: $24/mes
   - Render: $7/mes
```

---

### **Configuración Multi-Tenant (Opción Recomendada)**

```
AZURE SUBSCRIPTION
├── Resource Group: "SASU-Production"
│
├── 📦 Cosmos DB Account: "sasu-multitenancy"
│   ├── Database: "sasu_db"
│   │   ├── Container: tenants (NEW)
│   │   │   └── Partition Key: /tenant_id
│   │   │       - Guarda config de cada escuela
│   │   │
│   │   ├── Container: carnets
│   │   │   └── Partition Key: /tenant_id (CAMBIO)
│   │   │       - Ahora agrupa por escuela
│   │   │
│   │   ├── Container: notas
│   │   │   └── Partition Key: /tenant_id (CAMBIO)
│   │   │
│   │   ├── Container: citas
│   │   │   └── Partition Key: /tenant_id (CAMBIO)
│   │   │
│   │   ├── Container: usuarios
│   │   │   └── Partition Key: /tenant_id (CAMBIO)
│   │   │
│   │   └── Container: auditoria
│   │       └── Partition Key: /tenant_id (CAMBIO)
│   │
│   └── Throughput: 400-800 RU/s (escalable)
│
├── 🗄️ Azure Blob Storage: "sasufiles"
│   ├── Container: tenant-logos (NEW)
│   │   - Público (solo lectura)
│   │   - CDN enabled
│   │
│   └── Container: student-documents (NEW)
│       - Privado (requiere token)
│       - Estructura: {tenant_id}/{matricula}/{archivo}
│
└── 🔐 Azure Key Vault: "sasu-secrets" (OPCIONAL)
    ├── Cosmos DB Key
    ├── Storage Account Key
    └── JWT Secret

EXTERNO
└── ☁️ Render.com
    └── Backend FastAPI
        - Variable: COSMOS_URL
        - Variable: COSMOS_KEY
        - Variable: STORAGE_ACCOUNT_URL
        - Variable: STORAGE_ACCOUNT_KEY

💰 COSTO TOTAL: ~$50-80 USD/mes (10-20 escuelas)
   - Cosmos DB: $30-50/mes
   - Blob Storage: $5-10/mes
   - Render: $7/mes
   - Key Vault (opcional): $5/mes
```

---

### **Escalabilidad de Costos por Número de Clientes**

| Escuelas | Cosmos DB | Blob Storage | Backend | **TOTAL/mes** | Ingreso (promedio $150/escuela) | **Utilidad** |
|----------|-----------|--------------|---------|---------------|----------------------------------|--------------|
| 1 (actual) | $24 | $0 | $7 | **$31** | $0 | -$31 |
| 5 | $30 | $5 | $7 | **$42** | $750 | **$708** (94%) |
| 10 | $40 | $8 | $7 | **$55** | $1,500 | **$1,445** (96%) |
| 20 | $50 | $10 | $13 | **$73** | $3,000 | **$2,927** (97%) |
| 50 | $75 | $15 | $25 | **$115** | $7,500 | **$7,385** (98%) |
| 100 | $120 | $20 | $50 | **$190** | $15,000 | **$14,810** (98%) |

**💡 Observación Clave:**
- Con solo 5 clientes ya cubres costos y ganas $700+/mes
- Los costos NO crecen linealmente (economías de escala)
- Utilidad mejora mientras más clientes tengas

---

## 📅 PLAN DE IMPLEMENTACIÓN POR FASES <a name="fases"></a>

### **FASE 0: PREPARACIÓN (1-2 días)**

**Objetivo**: Tener todo listo antes de tocar código

#### **Tareas Azure:**
1. ✅ Crear nuevo Resource Group: "SASU-Production"
2. ✅ Crear Azure Blob Storage: "sasufiles"
   - Container: `tenant-logos` (acceso público)
   - Container: `student-documents` (acceso privado)
3. ✅ Obtener Storage Account Connection String
4. ✅ Configurar CORS en Blob Storage (permitir desde app)
5. ✅ Opcional: Crear Azure Key Vault para secrets

#### **Tareas Git:**
1. ✅ Crear branch: `feature/multi-tenant`
2. ✅ Verificar respaldo v2.4.33 existe
3. ✅ Documentar cambios a realizar

#### **Tareas Documentación:**
1. ✅ Crear documento de arquitectura
2. ✅ Definir estructura de tenant_id (ej: `primaria_benito_juarez`)
3. ✅ Diseñar JSON de configuración de tenant

**📝 Entregables:**
- [ ] Azure Blob Storage configurado
- [ ] Connection strings guardados
- [ ] Branch git creado
- [ ] Documento de arquitectura

**💰 Costo**: $0 (solo configuración)

---

### **FASE 1: BACKEND MULTI-TENANT (5-7 días)**

**Objetivo**: Backend puede manejar múltiples escuelas

#### **Día 1-2: Modelos de Datos**

**Archivo**: `temp_backend/models.py`

```python
# NUEVO: Modelo de Tenant
class TenantModel(BaseModel):
    tenant_id: str  # Primary key: "cres_llano_largo"
    nombre_escuela: str
    logo_url: str
    color_primario: str  # "#003366"
    color_secundario: str  # "#8B0000"
    telefono: str
    email: str
    direccion: str
    plan: str  # "basico", "estandar", "premium"
    activo: bool = True
    fecha_alta: str
    max_estudiantes: int = 500
    config_extra: dict = {}

# MODIFICAR: Todos los modelos existentes
class CarnetModel(BaseModel):
    tenant_id: str  # ← AGREGAR ESTE CAMPO
    matricula: str
    nombreCompleto: str
    # ... resto igual
```

**Cambios en:**
- `CarnetModel` → agregar `tenant_id`
- `NotaModel` → agregar `tenant_id`
- `CitaModel` → agregar `tenant_id`
- `UsuarioModel` → agregar `tenant_id`

#### **Día 3-4: Endpoints CRUD de Tenants**

**Archivo**: `temp_backend/tenant_routes.py` (NUEVO)

```python
@router.post("/tenants")
async def create_tenant(tenant: TenantModel):
    """Crear nueva escuela (solo super admin)"""
    pass

@router.get("/tenants")
async def list_tenants():
    """Listar todas las escuelas (solo super admin)"""
    pass

@router.get("/tenants/{tenant_id}")
async def get_tenant(tenant_id: str):
    """Obtener configuración de una escuela"""
    pass

@router.put("/tenants/{tenant_id}")
async def update_tenant(tenant_id: str, tenant: TenantModel):
    """Actualizar configuración de escuela"""
    pass

@router.post("/tenants/{tenant_id}/upload-logo")
async def upload_logo(tenant_id: str, file: UploadFile):
    """Subir logo a Azure Blob Storage"""
    pass
```

#### **Día 5-6: Modificar Endpoints Existentes**

**Cambiar TODOS los endpoints de carnets, notas, citas, usuarios**

**Antes:**
```python
@app.get("/carnet/{matricula}")
def get_carnet(matricula: str):
    result = carnets.query_items(
        "SELECT * FROM c WHERE c.matricula = @matricula",
        params=[{"name": "@matricula", "value": matricula}]
    )
```

**Después:**
```python
@app.get("/carnet/{matricula}")
def get_carnet(
    matricula: str, 
    current_user: dict = Depends(get_current_user)
):
    # Obtener tenant_id del usuario autenticado
    tenant_id = current_user["tenant_id"]
    
    result = carnets.query_items(
        "SELECT * FROM c WHERE c.tenant_id = @tenant_id AND c.matricula = @matricula",
        params=[
            {"name": "@tenant_id", "value": tenant_id},
            {"name": "@matricula", "value": matricula}
        ]
    )
```

**Archivos a modificar:**
- `main.py` → TODOS los endpoints de carnets (~10 endpoints)
- `main.py` → TODOS los endpoints de notas (~5 endpoints)
- `main.py` → TODOS los endpoints de citas (~8 endpoints)
- `auth_service.py` → Login debe retornar tenant_id en JWT

#### **Día 7: Testing y Deploy**

1. Crear 3 tenants de prueba en Cosmos DB
2. Probar que los datos NO se mezclan
3. Verificar que cada tenant solo ve sus datos
4. Deploy a Render.com

**📝 Entregables:**
- [ ] Modelo TenantModel creado
- [ ] CRUD de tenants funcionando
- [ ] Todos los endpoints filtran por tenant_id
- [ ] JWT incluye tenant_id
- [ ] Testing con 3 tenants dummy
- [ ] Deploy exitoso a Render

**💰 Costo**: $0 (mismo servidor actual)

---

### **FASE 2: CLIENTE MULTI-TENANT (5-7 días)**

**Objetivo**: App puede seleccionar escuela y cargar tema personalizado

#### **Día 1-2: Selector de Escuela en Login**

**Archivo**: `lib/screens/auth/login_screen.dart`

```dart
class LoginScreen extends StatefulWidget {
  // AGREGAR:
  String? _selectedTenantId;
  List<Tenant> _availableTenants = [];
  
  @override
  void initState() {
    super.initState();
    _loadAvailableTenants();  // Cargar lista de escuelas
  }
  
  Future<void> _loadAvailableTenants() async {
    // GET /tenants (solo retorna activos)
    final tenants = await ApiService.getActiveTenants();
    setState(() => _availableTenants = tenants);
  }
  
  // Widget dropdown
  DropdownButton<String>(
    hint: Text('Selecciona tu escuela'),
    value: _selectedTenantId,
    items: _availableTenants.map((t) => 
      DropdownMenuItem(value: t.tenantId, child: Text(t.nombreEscuela))
    ).toList(),
    onChanged: (val) => setState(() => _selectedTenantId = val),
  )
}
```

#### **Día 3-4: Servicio de Tenant**

**Archivo**: `lib/services/tenant_service.dart` (NUEVO)

```dart
class TenantConfig {
  final String tenantId;
  final String nombreEscuela;
  final String logoUrl;
  final Color colorPrimario;
  final Color colorSecundario;
  final String telefono;
  final String email;
  
  TenantConfig.fromJson(Map<String, dynamic> json)
    : tenantId = json['tenant_id'],
      nombreEscuela = json['nombre_escuela'],
      logoUrl = json['logo_url'],
      colorPrimario = _hexToColor(json['color_primario']),
      colorSecundario = _hexToColor(json['color_secundario']),
      telefono = json['telefono'],
      email = json['email'];
}

class TenantService {
  static TenantConfig? _currentConfig;
  
  static Future<void> loadConfig(String tenantId) async {
    final resp = await http.get(
      Uri.parse('$baseUrl/tenants/$tenantId')
    );
    _currentConfig = TenantConfig.fromJson(jsonDecode(resp.body));
  }
  
  static TenantConfig get current => _currentConfig!;
  
  static ThemeData get theme => ThemeData(
    primaryColor: _currentConfig!.colorPrimario,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _currentConfig!.colorPrimario,
    ),
    // ...
  );
}
```

#### **Día 5: Aplicar Tema Dinámico**

**Archivo**: `lib/main.dart`

```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeData _theme = AppTheme.light;  // Tema por defecto
  
  @override
  void initState() {
    super.initState();
    _loadTenantTheme();
  }
  
  Future<void> _loadTenantTheme() async {
    if (await AuthService.isLoggedIn()) {
      final user = await AuthService.getCurrentUser();
      await TenantService.loadConfig(user.tenantId);
      setState(() {
        _theme = TenantService.theme;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _theme,  // ← Tema dinámico
      // ...
    );
  }
}
```

#### **Día 6: Dashboard con Logo Personalizado**

**Archivo**: `lib/screens/dashboard_screen.dart`

```dart
// Reemplazar logo estático por logo dinámico
Container(
  child: TenantService.current.logoUrl.isNotEmpty
    ? Image.network(
        TenantService.current.logoUrl,
        height: 60,
        errorBuilder: (_, __, ___) => Icon(Icons.school, size: 60),
      )
    : Icon(Icons.school, size: 60),
)

// Mostrar nombre de escuela
Text(
  TenantService.current.nombreEscuela,
  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
)
```

#### **Día 7: Testing y Build**

1. Probar login con diferentes escuelas
2. Verificar que tema cambia correctamente
3. Verificar que logo se carga desde Azure
4. Build para Windows
5. Verificar que datos NO se mezclan

**📝 Entregables:**
- [ ] Selector de escuela en login
- [ ] TenantService funcionando
- [ ] Tema dinámico aplicado
- [ ] Logo personalizado visible
- [ ] Testing con 3 escuelas diferentes
- [ ] Build v2.5.0 (Multi-Tenant Alpha)

**💰 Costo**: $0

---

### **FASE 3: PANEL DE SUPER ADMIN (3-5 días)**

**Objetivo**: Tú puedes gestionar todas las escuelas

#### **Día 1-2: Dashboard de Admin**

**Archivo**: `lib/screens/super_admin/tenants_dashboard.dart` (NUEVO)

```dart
class TenantsDashboard extends StatefulWidget {
  // Lista de todas las escuelas
  // CRUD: Crear, editar, activar/desactivar
  // Ver métricas: estudiantes, usuarios, uso
}
```

**Funcionalidades:**
- ✅ Listar todas las escuelas
- ✅ Crear nueva escuela (formulario)
- ✅ Editar configuración de escuela
- ✅ Subir logo
- ✅ Activar/Desactivar escuela
- ✅ Ver estadísticas (# estudiantes, # usuarios, último acceso)

#### **Día 3: Formulario de Alta de Escuela**

```dart
class CreateTenantForm extends StatefulWidget {
  // Campos:
  // - Nombre de escuela
  // - Contacto (teléfono, email)
  // - Plan (básico/estándar/premium)
  // - Colores (color pickers)
  // - Logo (upload)
  // - Crear usuario admin inicial
}
```

#### **Día 4-5: Métricas y Reportes**

```dart
class AdminMetrics extends StatelessWidget {
  // Dashboard con:
  // - Total escuelas activas
  // - Total estudiantes en sistema
  // - Crecimiento mensual
  // - Ingresos proyectados
  // - Uso de almacenamiento
}
```

**📝 Entregables:**
- [ ] Panel de super admin funcionando
- [ ] CRUD completo de escuelas
- [ ] Upload de logos a Azure
- [ ] Métricas básicas
- [ ] Testing

**💰 Costo**: $0

---

### **FASE 4: MIGRACIÓN DE DATOS (1-2 días)**

**Objetivo**: Migrar datos actuales de CRES a estructura multi-tenant

#### **Opción A: Script de Migración (Recomendado)**

**Archivo**: `temp_backend/migrate_to_multitenant.py` (NUEVO)

```python
# Script que:
# 1. Lee TODOS los carnets actuales
# 2. Agrega tenant_id = "cres_llano_largo"
# 3. Re-inserta en Cosmos DB
# 4. Valida que todo se copió bien
# 5. Opcionalmente borra datos viejos

def migrate_carnets():
    # Leer todos
    old_carnets = carnets.query_items("SELECT * FROM c")
    
    for carnet in old_carnets:
        # Agregar tenant_id
        carnet['tenant_id'] = 'cres_llano_largo'
        
        # Re-insertar
        carnets.upsert_item(carnet)
    
    print(f"Migrados {len(old_carnets)} carnets")

migrate_carnets()
migrate_notas()
migrate_citas()
migrate_usuarios()
```

#### **Opción B: Doble Escritura Temporal**

```python
# Durante 1 semana, escribir en ambos formatos
# Después, script de cleanup
```

**📝 Entregables:**
- [ ] Script de migración probado
- [ ] Respaldo COMPLETO antes de migrar
- [ ] Datos migrados correctamente
- [ ] Validación de integridad
- [ ] Rollback plan documentado

**💰 Costo**: $0

**⚠️ CRÍTICO**: Hacer respaldo completo ANTES de migrar

---

### **FASE 5: FACTURACIÓN Y PAGOS (3-5 días) - OPCIONAL**

**Objetivo**: Cobrar automáticamente a las escuelas

#### **Integración con Stripe**

```python
# temp_backend/billing_routes.py
import stripe

@router.post("/billing/subscribe")
async def create_subscription(tenant_id: str, plan: str):
    # Crear customer en Stripe
    # Crear subscription
    # Actualizar tenant con subscription_id
    pass

@router.post("/billing/webhook")
async def stripe_webhook(request: Request):
    # Manejar eventos de Stripe:
    # - Pago exitoso → activar tenant
    # - Pago fallido → desactivar tenant
    # - Cancelación → marcar para cierre
    pass
```

**📝 Entregables:**
- [ ] Integración con Stripe
- [ ] Webhooks configurados
- [ ] Auto-activación/desactivación según pagos
- [ ] Generación de facturas

**💰 Costo**: $0 + 2.9% + $0.30 por transacción (Stripe)

---

## ✅ CHECKLIST COMPLETO DE TAREAS <a name="checklist"></a>

### **PREPARACIÓN**
- [ ] Crear Resource Group en Azure
- [ ] Crear Azure Blob Storage
- [ ] Configurar containers (tenant-logos, student-documents)
- [ ] Obtener connection strings
- [ ] Crear branch feature/multi-tenant
- [ ] Verificar respaldo v2.4.33

### **BACKEND**
- [ ] Crear TenantModel
- [ ] Agregar tenant_id a CarnetModel
- [ ] Agregar tenant_id a NotaModel
- [ ] Agregar tenant_id a CitaModel
- [ ] Agregar tenant_id a UsuarioModel
- [ ] Crear tenant_routes.py
- [ ] CRUD completo de tenants
- [ ] Endpoint upload logo
- [ ] Modificar TODOS los endpoints de carnets (filtrar por tenant_id)
- [ ] Modificar TODOS los endpoints de notas (filtrar por tenant_id)
- [ ] Modificar TODOS los endpoints de citas (filtrar por tenant_id)
- [ ] Modificar auth_service.py (JWT con tenant_id)
- [ ] Middleware de autorización por tenant
- [ ] Testing con 3 tenants dummy
- [ ] Deploy a Render

### **CLIENTE**
- [ ] Crear TenantService
- [ ] Selector de escuela en LoginScreen
- [ ] Cargar configuración al login
- [ ] Aplicar tema dinámico en main.dart
- [ ] Mostrar logo personalizado en dashboard
- [ ] Mostrar nombre de escuela en header
- [ ] Testing con diferentes escuelas
- [ ] Build v2.5.0

### **SUPER ADMIN**
- [ ] Crear TenantsDashboard
- [ ] Formulario de alta de escuela
- [ ] CRUD completo de escuelas
- [ ] Upload de logos
- [ ] Activar/Desactivar escuelas
- [ ] Panel de métricas
- [ ] Testing

### **MIGRACIÓN**
- [ ] Respaldo completo de datos actuales
- [ ] Script de migración
- [ ] Probar migración en ambiente de prueba
- [ ] Migrar datos de producción
- [ ] Validar integridad
- [ ] Documentar rollback

### **FACTURACIÓN (Opcional)**
- [ ] Crear cuenta Stripe
- [ ] Integración con Stripe API
- [ ] Webhooks configurados
- [ ] Testing de pagos
- [ ] Generación de facturas

### **MARKETING**
- [ ] Landing page
- [ ] Video demo
- [ ] Material de ventas (PDF)
- [ ] Casos de éxito
- [ ] Precios definidos
- [ ] Términos y condiciones
- [ ] Política de privacidad

---

## ⏱️ ESTIMACIÓN DE TIEMPOS Y COSTOS <a name="estimacion"></a>

### **Tiempo Total de Desarrollo**

| Fase | Días | Horas (8h/día) |
|------|------|----------------|
| Fase 0: Preparación | 1-2 | 8-16h |
| Fase 1: Backend Multi-Tenant | 5-7 | 40-56h |
| Fase 2: Cliente Multi-Tenant | 5-7 | 40-56h |
| Fase 3: Super Admin Panel | 3-5 | 24-40h |
| Fase 4: Migración | 1-2 | 8-16h |
| Fase 5: Facturación (opcional) | 3-5 | 24-40h |
| **TOTAL SIN FACTURACIÓN** | **15-23 días** | **120-184h** |
| **TOTAL CON FACTURACIÓN** | **18-28 días** | **144-224h** |

**Calendario Realista:**
- **Mínimo**: 3 semanas (tiempo completo, sin interrupciones)
- **Realista**: 4-6 semanas (con interrupciones, testing, bugs)
- **Conservador**: 8 semanas (part-time, con otros proyectos)

---

### **Costos de Infraestructura**

#### **Durante Desarrollo (1-2 meses)**
```
Azure Cosmos DB: $24/mes
Azure Blob Storage: $5/mes
Render.com: $7/mes
TOTAL: $36/mes × 2 = $72
```

#### **Producción (10 escuelas)**
```
Azure Cosmos DB: $40/mes
Azure Blob Storage: $8/mes
Render.com: $7/mes
TOTAL: $55/mes

INGRESOS: 10 escuelas × $150/mes = $1,500/mes
UTILIDAD: $1,445/mes (96%)
ROI: 26x
```

#### **Producción (50 escuelas)**
```
Azure Cosmos DB: $75/mes
Azure Blob Storage: $15/mes
Render.com: $25/mes
TOTAL: $115/mes

INGRESOS: 50 escuelas × $150/mes = $7,500/mes
UTILIDAD: $7,385/mes (98%)
ROI: 64x
```

---

### **Costo Total del Proyecto**

| Concepto | Costo |
|----------|-------|
| **Desarrollo** (180h × $0) | $0 (lo haces tú) |
| **Infraestructura Azure** (2 meses dev) | $72 |
| **Dominio** (.com) | $12/año |
| **SSL Certificate** (Let's Encrypt) | $0 |
| **Total Inversión Inicial** | **~$84** |

**Break-even**: Con solo **1 cliente pagando $150/mes**, recuperas inversión en 1 mes.

---

## ⚠️ RIESGOS Y MITIGACIONES <a name="riesgos"></a>

### **Riesgo 1: Fuga de Datos Entre Tenants** 🔴 CRÍTICO

**Descripción**: Un bug permite que Escuela A vea datos de Escuela B

**Probabilidad**: Media (si no se programa bien)

**Impacto**: CATASTRÓFICO (pérdida de confianza, demandas)

**Mitigación**:
1. ✅ SIEMPRE incluir `tenant_id` en queries
2. ✅ Middleware valida tenant_id en JWT vs tenant_id en request
3. ✅ Tests unitarios para cada endpoint
4. ✅ Auditoría completa (log de todos los accesos)
5. ✅ Revisión de código por tercero antes de producción
6. ✅ Penetration testing antes de vender

**Plan B**: Si ocurre fuga:
- Notificar inmediatamente a clientes afectados
- Suspender sistema 24h para auditoría
- Ofrecer 1 mes gratis + disculpa oficial
- Implementar fix + testing exhaustivo

---

### **Riesgo 2: Cosmos DB Se Llena Rápido** 🟡 MEDIO

**Descripción**: 50 escuelas × 5000 estudiantes = 250,000 registros. Cosmos DB cobra por RU/s.

**Probabilidad**: Alta (conforme creces)

**Impacto**: Medio (costo aumenta)

**Mitigación**:
1. ✅ Monitorear uso de RU/s mensualmente
2. ✅ Implementar TTL (Time To Live) en datos históricos
3. ✅ Archivar carnets de estudiantes graduados
4. ✅ Optimizar queries (índices, proyecciones)
5. ✅ Considerar Azure Table Storage para datos fríos

**Plan B**: Si costo se dispara:
- Migrar a PostgreSQL en Azure ($50-100/mes fijo)
- Implementar sharding manual
- Cobrar más a clientes grandes

---

### **Riesgo 3: Un Cliente Demanda Funcionalidad Custom** 🟡 MEDIO

**Descripción**: Escuela grande pide "queremos campo extra X, Y, Z"

**Probabilidad**: Alta

**Impacto**: Medio (distracción del roadmap)

**Mitigación**:
1. ✅ Vender paquetes FIJOS (no customización)
2. ✅ Plan Enterprise: Cotización aparte ($1000+/mes)
3. ✅ Campos personalizados en plan Premium
4. ✅ Decir "no" educadamente a requests fuera de plan

**Plan B**: Si cliente es muy importante:
- Cobrar $500-1000 por customización única
- Implementar solo si beneficia a TODOS los clientes
- Usar sistema de plugins (módulos opcionales)

---

### **Riesgo 4: Render.com Tiene Downtime** 🟡 MEDIO

**Descripción**: Render.com se cae, todas las escuelas sin servicio

**Probabilidad**: Baja (uptime 99.9%)

**Impacto**: Alto (pérdida de confianza)

**Mitigación**:
1. ✅ Monitoreo con UptimeRobot (gratis)
2. ✅ Notificaciones automáticas si servicio cae
3. ✅ SLA en contrato: "99% uptime garantizado"
4. ✅ Plan B: Migrar a Azure App Service ($13/mes)

**Plan B**: Si downtime frecuente:
- Migrar a Azure App Service (más caro pero más estable)
- O configurar multi-region deployment (avanzado)

---

### **Riesgo 5: No Consigues Clientes** 🟢 BAJO

**Descripción**: Sistema listo pero nadie compra

**Probabilidad**: Media-Baja (si marketing es débil)

**Impacto**: Alto (pérdida de inversión de tiempo)

**Mitigación**:
1. ✅ Validar con 3-5 escuelas ANTES de desarrollar
2. ✅ Ofrecer 1 mes gratis a primeros 10 clientes
3. ✅ Caso de éxito con CRES (ya funciona)
4. ✅ Demo en vivo a directores de escuela
5. ✅ Alianza con distribuidores de software educativo
6. ✅ LinkedIn ads targeting directores de escuela

**Plan B**: Si no vendes en 3 meses:
- Ofrecer como Open Source (ganar reputación)
- Vender como consultoría (instalaciones custom)
- Pivotar a otro mercado (clínicas, gimnasios)

---

## 🎯 RECOMENDACIÓN FINAL

### **Estrategia Sugerida: MVP en 4 Semanas**

**Semana 1**: Fase 0 + Fase 1 (Backend multi-tenant básico)
**Semana 2**: Fase 2 (Cliente multi-tenant)
**Semana 3**: Fase 3 (Super admin) + Fase 4 (Migración)
**Semana 4**: Testing exhaustivo + Deploy

**NO implementar facturación automática aún** (hacerlo manual primero)

**Validación**:
- Consigue 2-3 escuelas interesadas ANTES de empezar
- Ofrece "Early Access": $99/mes (descuento 50%)
- Primer mes gratis para feedback

**Después de 5 clientes pagando**:
- Implementar facturación automática (Stripe)
- Agregar funcionalidades premium
- Escalar marketing

---

## 📞 SIGUIENTE PASO

**¿Quieres que empiece con la Fase 0 (Preparación)?**

Podemos:
1. Crear Azure Blob Storage
2. Configurar estructura de directorios
3. Crear branch feature/multi-tenant
4. Diseñar JSON de configuración de tenant

O prefieres primero:
- Ver prototipo del panel admin
- Diseñar landing page de ventas
- Hacer proyección financiera más detallada

**Dime y arrancamos** 🚀
