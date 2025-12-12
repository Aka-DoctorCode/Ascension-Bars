# AscensionBars

![Version](https://img.shields.io/badge/Version-3.0.0-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![WoW Version](https://img.shields.io/badge/WoW-11.2.7_-_12.0-purple)
![Customizable](https://img.shields.io/badge/Customizable-Yes-orange)
![Status](https://img.shields.io/badge/Status-Active-brightgreen)

## 📖 Descripción

**AscensionBars** es un addon elegante y altamente personalizable para World of Warcraft que reemplaza las barras predeterminadas de experiencia y reputación con una interfaz moderna y configurable. Diseñado para ser limpio, eficiente y visualmente atractivo, ofrece una experiencia mejorada con opciones completas de personalización y rendimiento optimizado.

## ✨ Características Principales

### 🎨 **Personalización Completa**
- **Altura ajustable individual** para cada barra (1-50 píxeles)
- **Posicionamiento vertical libre** en toda la pantalla
- **Sistema de colores avanzado** con soporte de transparencia
- **Múltiples modos de visualización** (siempre visible, mouseover, ocultar en combate)

### ⚡ **Funcionalidades Avanzadas**
- **Barra de descanso visual** como superposición opcional
- **Texto de recompensas Paragon** con múltiples formatos de visualización
- **Soporte completo** para sistemas modernos (Renown, Paragon, Amistades)
- **Detección inteligente** de recompensas pendientes
- **Rendimiento optimizado** con caché y throttling configurable

### 🔧 **Panel de Configuración Integrado**
- Interfaz de configuración nativa dentro del juego
- Modo de vista previa en tiempo real
- Controles intuitivos (deslizadores, selectores de color, botones)
- Guardado automático de preferencias entre sesiones

## 📦 Instalación

1. **Descarga** la última versión de AscensionBars desde [WowInterface](https://www.wowinterface.com/) o [CurseForge](https://www.curseforge.com/).
2. **Extrae** el contenido del archivo ZIP descargado.
3. **Copia** la carpeta `AscensionBars` en tu directorio de addons:
   ```
   World of Warcraft\_retail_\Interface\AddOns\
   ```
4. **Inicia o recarga** World of Warcraft.
5. **Habilita** AscensionBars en el selector de addons (pantalla de personajes).

## ⚙️ Configuración

Accede a las opciones del addon a través de:

1. **Menú principal del juego** → **Interfaz** → **AddOns** → **Ascension Bars**
2. O utiliza el comando de chat: `/ab config`

### 📐 **Apariencia y Posición**

| Opción | Descripción | Valores |
|--------|-------------|---------|
| **Altura XP** | Controla la altura de la barra de experiencia | 1-50 píxeles |
| **Altura Reputación** | Controla la altura de la barra de reputación | 1-50 píxeles |
| **Posición Vertical (Y)** | Desplaza las barras verticalmente | -1080 a 0 |
| **Tamaño del Texto Paragon** | Controla el tamaño de fuente de las alertas | 8-30 |

### 🎨 **Sistema de Colores**

| Opción | Descripción | Predeterminado |
|--------|-------------|----------------|
| **Usar Color de Clase para XP** | Usa el color de tu clase para la barra de XP | Activado |
| **Color Personalizado XP** | Color personalizado para la barra de XP | Azul (0.0, 0.4, 0.9) |
| **Usar Colores de Reacción** | Colores según reacción de reputación | Activado |
| **Color Personalizado Rep** | Color uniforme para reputación | Verde (0.0, 1.0, 0.0) |
| **Color del Texto** | Color para todo el texto informativo | Blanco (1.0, 1.0, 1.0) |
| **Mostrar Barra de Descanso** | Superposición visual para XP descansado | Activado |
| **Color de Descanso** | Color para la superposición de descanso | Púrpura (0.6, 0.4, 0.8) |

### 👁️ **Visibilidad**

| Opción | Descripción | Recomendación |
|--------|-------------|---------------|
| **Mostrar Solo al Pasar el Ratón** | Las barras aparecen solo al hacer hover | Desactivado |
| **Ocultar en Combate** | Esconde las barras durante peleas | Desactivado |
| **Modo Configuración** | Muestra todos los elementos para ajustes | Temporal |

### 📝 **Texto de Recompensas**

| Opción | Descripción | Efecto |
|--------|-------------|--------|
| **Texto Separado en Partes Superiores** | Mantiene el texto en la parte superior de la pantalla | Mejor visibilidad |
| **Mostrar Líneas Separadas** | Muestra cada recompensa en su propia línea | Para múltiples recompensas |
| **Espaciado del Texto** | Controla el espacio entre líneas | 0-50 píxeles |
| **Offset Vertical del Texto** | Posiciona el texto verticalmente | -800 a 50 |

## 🚀 Uso Rápido

### Al Instalar por Primera Vez:
1. El addon reemplaza automáticamente las barras predeterminadas de Blizzard.
2. Las barras aparecerán en la parte superior de la pantalla con la configuración predeterminada.
3. ¡Listo para jugar!

### Personalización Avanzada:
1. Abre el panel de configuración.
2. Activa el **Modo Configuración** para ver los cambios en tiempo real.
3. Ajusta colores, posiciones y visibilidad según tus preferencias.
4. Desactiva el Modo Configuración cuando hayas terminado.

## 📊 Información Mostrada

### Barra de Experiencia:
- **Nivel actual** y progreso hacia el siguiente
- **Experiencia actual / máxima** del nivel
- **Porcentaje de progreso** exacto
- **Descanso acumulado** (cuando está disponible)
- **Cambio de color** cuando hay descanso disponible

### Barra de Reputación:
- **Nombre de la facción** seguida
- **Estado actual** (Hostil, Neutral, Amistoso, Honrado, etc.)
- **Progreso hacia el siguiente nivel** de reputación
- **Sistemas especiales** indicados claramente:
  - ✅ **Renown** (con nivel actual)
  - 🔄 **Paragon** (progreso circular)
  - 💖 **Amistades** (relaciones especiales)

### Alertas de Recompensas:
- **Notificaciones visibles** para recompensas Paragon pendientes
- **Formato claro** para múltiples facciones simultáneamente
- **Destacado en color verde brillante** para máxima visibilidad
- **Posicionamiento flexible** (superior o dinámico)

## 🔧 Solución de Problemas

### Problemas Comunes y Soluciones:

| Problema | Solución |
|----------|----------|
| **Las barras no aparecen** | 1. Verifica que el addon esté habilitado<br>2. Recarga la interfaz con `/reload`<br>3. Comprueba conflictos con otros addons |
| **La configuración no se guarda** | 1. Asegúrate de salir del juego normalmente<br>2. Verifica permisos de escritura en la carpeta WTF |
| **Texto superpuesto o mal posicionado** | 1. Ajusta los valores de altura y posición<br>2. Reduce el tamaño de fuente si es necesario<br>3. Aumenta el espaciado entre elementos |
| **Rendimiento lento en ciudades** | 1. Aumenta el throttling de escaneo Paragon<br>2. Desactiva actualizaciones frecuentes |
| **Conflictos con otros addons** | 1. Desactiva otros addons de barras de progreso<br>2. Asegúrate de tener la última versión |

### Comandos de Chat Útiles:
- `/reload` - Recarga completamente la interfaz de usuario
- `/ab` o `/ascensionbars` - Acceso rápido al panel de configuración
- `/framestack` - Herramienta de depuración para elementos de interfaz

## 📁 Estructura del Proyecto

```
AscensionBars/
├── AscensionBars.toc           # Metadatos y dependencias del addon
├── AscensionBars.lua           # Código principal (v3.0.0)
├── LICENSE                     # Licencia MIT
└── README.md                   # Este archivo
```

### Variables Guardadas:
El addon guarda la configuración en:
```
WTF\Account\[CUENTA]\[SERVIDOR]\[PERSONAJE]\SavedVariables\AscensionBars.lua
```

## 🤝 Contribuciones

¡Las contribuciones son bienvenidas! Si deseas mejorar AscensionBars:

1. **Reporta errores** abriendo un issue en el repositorio.
2. **Sugiere nuevas características** con descripciones detalladas.
3. **Envía Pull Requests** con mejoras documentadas.
4. **Traduce** el addon a otros idiomas.

### Guías para Contribuir:
- Mantén el código limpio y bien comentado.
- Sigue el estilo de codificación existente.
- Incluye documentación para cambios importantes.
- Prueba tus cambios en diferentes situaciones de juego.

## 📄 Licencia

Este proyecto está bajo la **Licencia MIT**. Esto significa que puedes:

- ✅ Usar, copiar y modificar el software libremente
- ✅ Distribuir copias del software
- ✅ Usar el software comercialmente
- ✅ Modificar el software y distribuir modificaciones

La única condición es incluir el aviso de copyright y licencia original.

**Texto completo de la licencia disponible en el archivo LICENSE.**

## 🙏 Agradecimientos

### Créditos:
- **Desarrollador Principal**: [Tu Nombre/Apodo]
- **Inspiración**: Comunidad de addons de World of Warcraft
- **Probadores Beta**: Todos los jugadores que ayudaron a refinar el addon
- **Soporte Técnico**: Foros de WowInterface y comunidades de desarrollo

### Recursos Utilizados:
- **Iconos y Texturas**: Sistema de interfaz nativo de World of Warcraft
- **Fuentes**: Friz Quadrata (fuente estándar de WoW)
- **Herramientas**: VS Code, Git, WoW Addon Studio

## 🔗 Enlaces y Recursos

### Descarga:
- **[WowInterface](https://www.wowinterface.com/downloads/infoXXXXX-AscensionBars.html)** - Versión principal
- **[CurseForge](https://www.curseforge.com/wow/addons/ascensionbars)** - Alternativa

### Soporte y Comunidad:
- **[Foros de WowInterface](https://www.wowinterface.com/forums/forumdisplay.php?f=89)** - Discusión y soporte
- **[GitHub Issues](https://github.com/tuusuario/AscensionBars/issues)** - Reportar bugs
- **[Discord del Desarrollador](https://discord.gg/tuinvitacion)** - Comunidad activa

### Proyectos Relacionados:
- **Bartender4** - Barras de acción personalizables
- **SexyMap** - Minimapa mejorado
- **WeakAuras** - Sistema avanzado de alertas

## 📞 Soporte y Contacto

### Para Ayuda:
1. **Consulta primero** esta documentación y la sección de solución de problemas.
2. **Busca en los foros** si alguien ya reportó tu problema.
3. **Abre un issue** en GitHub para bugs confirmados.
4. **Únete al Discord** para discusiones en tiempo real.

### Información de Contacto:
- **Email**: [tuemail@ejemplo.com]
- **WowInterface**: [TuPerfilEnWowInterface]
- **Twitter**: [@TuUsuario]

---

## 📋 Historial de Versiones

### v3.0.0 (Actual)
- **NUEVO**: Panel de configuración completo integrado en el juego
- **NUEVO**: Sistema de personalización total con modo vista previa
- **NUEVO**: Soporte para barra de descanso como superposición visual
- **MEJORA**: Rendimiento optimizado con caché y throttling
- **CORRECCIÓN**: Bug visual al alcanzar nivel máximo
- **CORRECCIÓN**: Manejo correcto de eventos de combate

### v2.0.1 (Anterior)
- Versión inicial estable con barras básicas de XP y reputación
- Soporte para sistemas Paragon y Renown
- Ocultamiento automático de barras predeterminadas de Blizzard

---

## ⚠️ Descargo de Responsabilidad

**AscensionBars** es un addon de fan creado por la comunidad. No está afiliado, respaldado ni aprobado por Blizzard Entertainment, Inc. World of Warcraft, Warcraft y Blizzard Entertainment son marcas registradas de Blizzard Entertainment, Inc. en los EE. UU. y otros países.

Este software se proporciona "TAL CUAL", sin garantías de ningún tipo. El desarrollador no se hace responsable de ningún daño o problema causado por el uso de este addon.

---

**¡Gracias por usar AscensionBars! ¡Buena suerte en tus aventuras en Azeroth!** 🎮⚔️✨

*"La experiencia no es solo un número, es un viaje."*
