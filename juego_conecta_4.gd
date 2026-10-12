extends Control

const FILAS = 6
const COLUMNAS = 7

var tablero: Array = []
var turno_jugador: bool = true
var juego_terminado: bool = false
var dificultad_actual: String = "Facil"

# Referencias directas a los contenedores principales ------------------------------------------------
@onready var menu_principal: VBoxContainer = $MenuPrincipal
@onready var menu_dificultad: VBoxContainer = $MenuDificultad
@onready var area_juego: VBoxContainer = $AreaJuego

@onready var label_turno: Label = $AreaJuego/LabelTurno
@onready var grid_container: GridContainer = $AreaJuego/GridContainer
@onready var dialog_fin: AcceptDialog = $AcceptDialog

func _ready() -> void:
	configurar_textos_y_estilos()
	conectar_senales_botones()
	mostrar_menu_principal()

func configurar_textos_y_estilos() -> void:
	label_turno.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_turno.custom_minimum_size = Vector2(0, 40)

	# Textos del Menú Principal  ------------------------------------------------------------------------------------------------
	if has_node("MenuPrincipal/Conecta 4"):
		get_node("MenuPrincipal/Conecta 4").text = "CONECTA 4 - IA"
	if has_node("MenuPrincipal/BtnJugar"):
		$MenuPrincipal/BtnJugar.text = "Iniciar Partida"
	if has_node("MenuPrincipal/BtnSalir"):
		$MenuPrincipal/BtnSalir.text = "Salir"
		
	# textos en general lol  -------------------------------------------------------------------------------------------------------
	if has_node("MenuDificultad/SeleccionNivelDificultad"):
		$MenuDificultad/SeleccionNivelDificultad.text = "Selecciona el Nivel de Dificultad"
	if has_node("MenuDificultad/BtnFacil"):
		$MenuDificultad/BtnFacil.text = "Fácil"
	if has_node("MenuDificultad/BtnMedio"):
		$MenuDificultad/BtnMedio.text = "Medio"
	if has_node("MenuDificultad/BtnDificil"):
		$MenuDificultad/BtnDificil.text = "Difícil"
	if has_node("MenuDificultad/BtnVolverMenu"):
		$MenuDificultad/BtnVolverMenu.text = "Volver al Menú"
	if has_node("AreaJuego/BtnRegresarMenu"):
		$AreaJuego/BtnRegresarMenu.text = "Volver al Menú Principal"

func conectar_senales_botones() -> void:
	# Conexiones ------------------------------------------------------------------------------------------
	var btn_jugar = get_node_or_null("MenuPrincipal/BtnJugar")
	if btn_jugar and not btn_jugar.pressed.is_connected(mostrar_menu_dificultad):
		btn_jugar.pressed.connect(mostrar_menu_dificultad)
		
	var btn_salir = get_node_or_null("MenuPrincipal/BtnSalir")
	if btn_salir and not btn_salir.pressed.is_connected(_salir_aplicacion):
		btn_salir.pressed.connect(_salir_aplicacion)
	
	var btn_facil = get_node_or_null("MenuDificultad/BtnFacil")
	if btn_facil and not btn_facil.pressed.is_connected(func(): iniciar_partida("Facil")):
		btn_facil.pressed.connect(func(): iniciar_partida("Facil"))
		
	var btn_medio = get_node_or_null("MenuDificultad/BtnMedio")
	if btn_medio and not btn_medio.pressed.is_connected(func(): iniciar_partida("Medio")):
		btn_medio.pressed.connect(func(): iniciar_partida("Medio"))
		
	var btn_dificil = get_node_or_null("MenuDificultad/BtnDificil")
	if btn_dificil and not btn_dificil.pressed.is_connected(func(): iniciar_partida("Dificil")):
		btn_dificil.pressed.connect(func(): iniciar_partida("Dificil"))
		
	var btn_volver_1 = get_node_or_null("MenuDificultad/BtnVolverMenu")
	if btn_volver_1 and not btn_volver_1.pressed.is_connected(mostrar_menu_principal):
		btn_volver_1.pressed.connect(mostrar_menu_principal)
		
	var btn_volver_2 = get_node_or_null("AreaJuego/BtnRegresarMenu")
	if btn_volver_2 and not btn_volver_2.pressed.is_connected(mostrar_menu_principal):
		btn_volver_2.pressed.connect(mostrar_menu_principal)
		
	# diálogo de fin de partida ----------
	if dialog_fin and not dialog_fin.confirmed.is_connected(mostrar_menu_principal):
		dialog_fin.confirmed.connect(mostrar_menu_principal)

func _salir_aplicacion() -> void:
	get_tree().quit()

func mostrar_menu_principal() -> void:
	if menu_principal: menu_principal.visible = true
	if menu_dificultad: menu_dificultad.visible = false
	if area_juego: area_juego.visible = false
	juego_terminado = true

func mostrar_menu_dificultad() -> void:
	if menu_principal: menu_principal.visible = false
	if menu_dificultad: menu_dificultad.visible = true
	if area_juego: area_juego.visible = false

func iniciar_partida(dificultad: String) -> void:
	dificultad_actual = dificultad
	if menu_principal: menu_principal.visible = false
	if menu_dificultad: menu_dificultad.visible = false
	if area_juego: area_juego.visible = true
	
	inicializar_tablero_logico()
	construir_interfaz_tablero()
	turno_jugador = true
	juego_terminado = false
	actualizar_indicador_turno()
	actualizar_vista_tablero()

func inicializar_tablero_logico() -> void:
	tablero = []
	for f in range(FILAS):
		var fila = []
		for c in range(COLUMNAS):
			fila.append(0)
		tablero.append(fila)

func construir_interfaz_tablero() -> void:
	for hijo in grid_container.get_children():
		hijo.queue_free()
		
	grid_container.columns = COLUMNAS
	for f in range(FILAS):
		for c in range(COLUMNAS):
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(50, 50)
			btn.pressed.connect(_on_columna_clicada.bind(c))
			grid_container.add_child(btn)

func _on_columna_clicada(columna: int) -> void:
	if juego_terminado or not turno_jugador:
		return
		
	var fila_libre = obtener_fila_disponible(tablero, columna)
	if fila_libre != -1:
		tablero[fila_libre][columna] = 1
		actualizar_vista_tablero()
		
		if verificar_ganador(tablero, 1):
			terminar_juego("¡Ganaste!")
			return
			
		if tablero_lleno(tablero):
			terminar_juego("¡Empate!")
			return
			
		turno_jugador = false
		actualizar_indicador_turno()
		
		await get_tree().create_timer(0.4).timeout
		turno_ia()

func turno_ia() -> void:
	if juego_terminado:
		return
		
	var col_ia = -1
	
	match dificultad_actual:
		"Facil":
			col_ia = obtener_movimiento_aleatorio()
		"Medio":
			col_ia = obtener_movimiento_medio()
		"Dificil":
			col_ia = obtener_movimiento_dificil()
			
	if col_ia != -1:
		var fila_libre = obtener_fila_disponible(tablero, col_ia)
		if fila_libre != -1:
			tablero[fila_libre][col_ia] = 2
			
			if verificar_ganador(tablero, 2):
				actualizar_vista_tablero()
				terminar_juego("¡Perdiste!")
				return
				
			if tablero_lleno(tablero):
				actualizar_vista_tablero()
				terminar_juego("¡Empate!")
				return
				
	turno_jugador = true
	actualizar_vista_tablero()
	actualizar_indicador_turno()

# niveles de la IA  ------------------------------------------------------------------------------------------------------------
func obtener_movimiento_aleatorio() -> int:
	var disponibles = []
	for c in range(COLUMNAS):
		if tablero[0][c] == 0:
			disponibles.append(c)
	if disponibles.size() > 0:
		return disponibles[randi() % disponibles.size()]
	return -1

func obtener_movimiento_medio() -> int:
	for c in range(COLUMNAS):
		var f = obtener_fila_disponible(tablero, c)
		if f != -1:
			tablero[f][c] = 2
			if verificar_ganador(tablero, 2):
				tablero[f][c] = 0
				return c
			tablero[f][c] = 0
			
	for c in range(COLUMNAS):
		var f = obtener_fila_disponible(tablero, c)
		if f != -1:
			tablero[f][c] = 1
			if verificar_ganador(tablero, 1):
				tablero[f][c] = 0
				return c
			tablero[f][c] = 0
			
	return obtener_movimiento_aleatorio()

func obtener_movimiento_dificil() -> int:
	var mejor_puntaje = -999999
	var mejor_columna = obtener_movimiento_aleatorio()
	
	for c in range(COLUMNAS):
		var f = obtener_fila_disponible(tablero, c)
		if f != -1:
			tablero[f][c] = 2
			var puntaje = minimax(tablero, 3, false, -999999, 999999)
			tablero[f][c] = 0
			if puntaje > mejor_puntaje:
				mejor_puntaje = puntaje
				mejor_columna = c
	return mejor_columna

func minimax(nodo_tablero: Array, profundidad: int, es_maximizando: bool, alfa: float, beta: float) -> float:
	if verificar_ganador(nodo_tablero, 2): return 100000
	if verificar_ganador(nodo_tablero, 1): return -100000
	if profundidad == 0 or tablero_lleno(nodo_tablero):
		return evaluar_tablero(nodo_tablero)
		
	if es_maximizando:
		var max_eval = -999999
		for c in range(COLUMNAS):
			var f = obtener_fila_disponible(nodo_tablero, c)
			if f != -1:
				nodo_tablero[f][c] = 2
				var eval = minimax(nodo_tablero, profundidad - 1, false, alfa, beta)
				nodo_tablero[f][c] = 0
				max_eval = max(max_eval, eval)
				alfa = max(alfa, eval)
				if beta <= alfa:
					break
		return max_eval
	else:
		var min_eval = 999999
		for c in range(COLUMNAS):
			var f = obtener_fila_disponible(nodo_tablero, c)
			if f != -1:
				nodo_tablero[f][c] = 1
				var eval = minimax(nodo_tablero, profundidad - 1, true, alfa, beta)
				nodo_tablero[f][c] = 0
				min_eval = min(min_eval, eval)
				beta = min(beta, eval)
				if beta <= alfa:
					break
		return min_eval

func evaluar_tablero(t: Array) -> int:
	var puntaje = 0
	for f in range(FILAS):
		if t[f][3] == 2: puntaje += 5
	return puntaje

func obtener_fila_disponible(t: Array, columna: int) -> int:
	for f in range(FILAS - 1, -1, -1):
		if t[f][columna] == 0:
			return f
	return -1

func tablero_lleno(t: Array) -> bool:
	for c in range(COLUMNAS):
		if t[0][c] == 0: return false
	return true

func actualizar_vista_tablero() -> void:
	var celdas = grid_container.get_children()
	for f in range(FILAS):
		for c in range(COLUMNAS):
			var index = f * COLUMNAS + c
			var valor = tablero[f][c]
			var boton = celdas[index] as Button
			if valor == 1:
				boton.text = "🔴"
				boton.disabled = true
			elif valor == 2:
				boton.text = "🟡"
				boton.disabled = true
			else:
				boton.text = ""
				boton.disabled = false if turno_jugador else true

func actualizar_indicador_turno() -> void:
	if turno_jugador:
		label_turno.text = "Dificultad: " + dificultad_actual

func verificar_ganador(t: Array, jugador: int) -> bool:
	for f in range(FILAS):
		for c in range(COLUMNAS - 3):
			if t[f][c] == jugador and t[f][c+1] == jugador and t[f][c+2] == jugador and t[f][c+3] == jugador: return true
	for f in range(FILAS - 3):
		for c in range(COLUMNAS):
			if t[f][c] == jugador and t[f+1][c] == jugador and t[f+2][c] == jugador and t[f+3][c] == jugador: return true
	for f in range(3, FILAS):
		for c in range(COLUMNAS - 3):
			if t[f][c] == jugador and t[f-1][c+1] == jugador and t[f-2][c+2] == jugador and t[f-3][c+3] == jugador: return true
	for f in range(FILAS - 3):
		for c in range(COLUMNAS - 3):
			if t[f][c] == jugador and t[f+1][c+1] == jugador and t[f+2][c+2] == jugador and t[f+3][c+3] == jugador: return true
	return false

func terminar_juego(mensaje: String) -> void:
	juego_terminado = true
	label_turno.text = mensaje
	dialog_fin.dialog_text = mensaje + " Regresando al menú principal."
	dialog_fin.popup_centered()
