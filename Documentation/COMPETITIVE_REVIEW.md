# Evaluación de CleanMyMac y herramientas abiertas

**Revisado:** 2026-10-06. Esta revisión sirve para orientar producto y arquitectura de Mac Guardian; no es una auditoría de seguridad del código de terceros.

## Material encontrado en la raíz

- `README 2.md` describe **CleanMyMac CLI**, la herramienta de terminal de MacPaw: análisis de disco, limpieza de cachés de herramientas de desarrollo, purga de artefactos de proyectos y acciones de optimización. Está marcada como beta pública.
- Aunque su código está publicado en GitHub, CleanMyMac CLI **no es open source**: su licencia lo define como software propietario y limita el uso a fines personales no comerciales. Podemos aprender de las funciones y del flujo descrito; no debemos copiar ni reutilizar código, recursos o lógica protegida sin autorización.
- `SECURITY.md` en la raíz es una política para reportar vulnerabilidades en repositorios de MacPaw, no la política de seguridad de Mac Guardian. No la interpreto como una decisión de producto nuestra.

Fuentes: [README de CleanMyMac CLI](https://github.com/MacPaw/cleanmymac-cli), [licencia](https://github.com/MacPaw/cleanmymac-cli/blob/main/LICENSE), [Security Policy copiada](https://github.com/MacPaw/cleanmymac-cli/blob/main/SECURITY.md).

El producto comercial CleanMyMac ofrece una superficie más amplia que el CLI. Su Smart Care coordina limpieza, protección, rendimiento, aplicaciones y My Clutter; sus herramientas incluyen desinstalación y actualización de apps, elementos de inicio, archivos grandes/antiguos y duplicados. Algunas capacidades varían según el canal de distribución. Esto ayuda a mapear expectativas del mercado, pero no significa que todas deban entrar en el MVP. Fuentes: [Smart Care](https://macpaw.com/support/cleanmymac/knowledgebase/smart-care), [catálogo de herramientas](https://macpaw.com/support/cleanmymac/knowledgebase/my-tools), [diferencias de la versión del App Store](https://macpaw.com/support/cleanmymac-x/knowledgebase/missing-features).

## Ideas útiles para Mac Guardian

### Adoptar como principios de producto

1. **Separar el análisis de la acción.** Explorar almacenamiento no modifica archivos. Un usuario puede navegar, ordenar y abrir Finder antes de crear un plan de limpieza.
2. **Agrupar por procedencia y contexto.** Mantener separadas las cachés compartidas de herramientas y los artefactos dentro de proyectos. Mostrar el proyecto asociado evita que `node_modules`, `.build` o `DerivedData` parezcan archivos desconocidos.
3. **Explicar cada hallazgo.** En cada fila, mostrar ruta, tamaño, origen detectado, por qué apareció, nivel de riesgo, permiso que falta y qué acción es reversible. Los hallazgos inciertos deben quedar fuera de una selección segura predeterminada.
4. **Dar resultados incrementales y cancelables.** Una categoría por vez, progreso visible y resultados parciales conservados al cancelar reducen la espera y hacen el análisis verificable.
5. **Contabilizar espacio sin duplicarlo.** Si un caché ya está incluido en una categoría de app, no volver a sumarlo. Mostrar elementos omitidos o inaccesibles y diferenciar “cero encontrado” de “no se pudo leer”.
6. **Permitir excluir rutas.** Una lista local de exclusiones que solo reduzca el conjunto analizado da control durable al usuario.
7. **Tratar artefactos de proyecto con prudencia.** Un umbral de antigüedad puede ordenar o sugerir una revisión, pero no debe auto-seleccionar nada. Antes de proponer limpieza, comprobar señales de uso activo y presentar los datos que sostienen la sugerencia.
8. **Desinstalar con coincidencias graduadas.** Bundle ID y app group pueden ofrecer coincidencias fuertes; heurísticas por nombre deben ser menos confiables, explicadas y desmarcadas hasta que el usuario las revise. No borrar componentes compartidos por el proveedor de forma implícita.
9. **Preferir Trash cuando el sistema lo permita.** Indicar con claridad qué irá a Trash y qué se borrará permanentemente. Vaciar Trash debe ser una acción independiente.
10. **Mantener un historial comprensible.** Registrar selección, motivo, resultado y espacio recuperado después de verificarlo, sin guardar contenido privado innecesario.

Estos principios ya encajan con `SECURITY.md`, `PERMISSIONS.md` y el roadmap actual. Los candidatos más cercanos a Phase 2 son análisis de almacenamiento por categorías, conteo no duplicado, progreso/cancelación y resultados parciales; las exclusiones y explicaciones por fila preparan Phase 3.

Las prácticas descritas por [Purge](https://github.com/jithin-sabu/purge-app) son especialmente pertinentes: movimiento a Trash, etiquetas explicables, exclusiones, resultados incrementales, chequeos de repositorios/lockfiles y comprobación fresca antes de mover duplicados. Son patrones declarados por el proyecto, no garantías que hayamos verificado independientemente.

### Explorar más adelante

- Un Space Explorer tipo treemap o navegación por directorios ordenados por tamaño.
- Un desinstalador con sensibilidad configurable y revisión por app.
- Encontrar artefactos de más ecosistemas de desarrollo y modelos locales de IA, empezando por las ubicaciones públicas y conocidas.
- Accesos rápidos de teclado y un flujo Smart Scan que coordine módulos sin esconder qué analizó ni qué propone.
- Un auditor de protección que reporte estado observado y “desconocido” cuando una comprobación pública no alcance.

[PureMac](https://github.com/momenbasel/PureMac) documenta límites honestos (por ejemplo, no prometer liberar espacio purgable ni “acelerar RAM”), tamaños asignados, exclusiones y revalidación de duplicados; su licencia declara MIT. [MyMacCleaner](https://github.com/Prot10/MyMacCleaner) sirve como referencia de superficie funcional y organización de módulos SwiftUI, pero su README también recomienda permitir una app bloqueada por Gatekeeper; Mac Guardian no debe seguir esa instrucción ni pedir que se debiliten protecciones.

### No adoptar como comportamiento predeterminado

- **Auto-limpieza programada, `--force` o borrado sin revisión.** CleanMyMac CLI documenta `--force`, y algunas apps permiten tareas automáticas. Mac Guardian requiere consentimiento informado y el proyecto prioriza control por operación.
- **Preseleccionar por edad.** La edad ayuda a ordenar, pero no prueba que un archivo se pueda borrar. Artefactos de un proyecto activo pueden seguir siendo necesarios.
- **Promesas de RAM “liberada”, velocidad garantizada o espacio purgable recuperable.** Reportar observaciones medibles; no vender optimizaciones especulativas.
- **Borrar historial, cookies, contraseñas, adjuntos u otros datos personales como “basura”.** Si se añade privacidad, cada dato debe ser opcional, identificable y revisable.
- **Permisos más amplios de los necesarios o mecanismos privilegiados genéricos.** Un helper y Full Disk Access son capacidades sensibles, no atajos para simplificar arquitectura.

## Revisión del topic de GitHub

Las páginas [`mac-cleaner`](https://github.com/topics/mac-cleaner) y [`macos-cleaner`](https://github.com/topics/macos-cleaner) son directorios comunitarios dinámicos; al revisarlas mostraban decenas de proyectos con calidad, madurez y licencias distintas. El topic es buen punto de partida para descubrir implementaciones, no una curaduría ni una señal de seguridad.

Selección de referencias examinadas:

| Proyecto | Valor como referencia | Precauciones |
| --- | --- | --- |
| [Purge](https://github.com/jithin-sabu/purge-app) | Flujo de revisión y Trash, exclusiones, hallazgos explicados, señales de proyecto activo y manejo prudente de duplicados. | No hemos auditado su código ni probado su comportamiento en macOS. Usar solo ideas hasta hacer una revisión específica. |
| [PureMac](https://github.com/momenbasel/PureMac) | App SwiftUI + CLI, navegación por espacio, límites honestos sobre optimización y enfoque visible de privacidad. | Su README declara MIT; cualquier reutilización literal requeriría conservar avisos y revisar archivos/dependencias concretos. No adoptar limpieza automática. |
| [Pearcleaner](https://github.com/alienator88/Pearcleaner) | Referencias para desinstalación, búsqueda de residuos, filtros y rutas personalizables. | Su estado publicado es “On Hold”; su Apache 2.0 + Commons Clause restringe monetización, por lo que no es una base licenciable para nuestro producto comercial. |
| [MyMacCleaner](https://github.com/Prot10/MyMacCleaner) | Ejemplo amplio de módulos SwiftUI y mapa de funciones. | El README declara MIT, pero recomienda permitir la ejecución de una descarga bloqueada por Gatekeeper. Ignorar esa recomendación; revisar código y licencias de dependencias antes de cualquier reutilización. |

No descargué ni ejecuté repositorios de terceros. La evaluación de arriba usa sus páginas, README y licencias publicadas; las funciones, calidad del código, cadena de suministro y seguridad necesitan revisión independiente antes de reutilizar implementación alguna.

## Próxima decisión sugerida

La base de análisis incremental, acceso a Finder, cachés de desarrollo, inventario de apps y auditoría de inicio ya está implementada. El siguiente trabajo útil es reforzar los motivos de omisión, evitar doble conteo de archivos compartidos, validar de nuevo los objetivos antes de moverlos a Trash y diseñar una revisión explícita de residuos de apps. Los permisos avanzados, duplicados y limpieza automática siguen fuera del alcance actual.
