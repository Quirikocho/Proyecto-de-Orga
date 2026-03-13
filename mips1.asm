# macros
.macro imprimir_str(%label) # macro para imprimir una cadena de caracteres
    li $v0, 4
    la $a0, %label
    syscall
.end_macro

.macro leer_str(%buffer, %size) # macro para leer una cadena de caracteres (String)
    li $v0, 8
    la $a0, %buffer
    li $a1, %size 
    syscall
.end_macro

.macro m_ProcesarSigno(%ptr_reg, %signo_reg)
    lbu $t0, 0(%ptr_reg)    # cargar el primer byte
    li %signo_reg, 0        # por defecto es positivo (0)
    
    li $t1, 45              # ASCII de '-'
    beq $t0, $t1, es_negativo
    
    li $t1, 43              # ASCII de '+'
    beq $t0, $t1, es_positivo
    j fin_macro             # si no hay signo, no avanzamos el puntero
    
es_negativo:
    li %signo_reg, 1        # marcar como negativo
es_positivo:
    addi %ptr_reg, %ptr_reg, 1 # avanzar el puntero para saltar el signo
    
fin_macro:
.end_macro

.macro m_AplicarComplemento2(%reg_valor)
    not %reg_valor, %reg_valor  # invertir todos los bits (Bitwise NOT)
    addi %reg_valor, %reg_valor, 1 # sumar 1
.end_macro

.macro m_ConvertirFraccion(%ptr_reg, %reg_res_frac)
    # %ptr_reg: Puntero al string despues del '.'
    # %reg_res_frac: Registro donde guardaremos los 8 bits
    
    li %reg_res_frac, 0       # limpiar el resultado
    li $t2, 0                 # contador de bits (maximo 8)
    li $t3, 10                # constante para multiplicar/dividir
    
    # PASO 1: Convertir el string de la fraccion a un entero
    # Ej: de ".75" a 75
    li $t4, 0                 # valor acumulado
    li $t5, 1                 # multiplicador (potencia de 10) para el divisor
loop_ascii:
    lbu $t0, 0(%ptr_reg)
    beq $t0, $zero, iniciar_multiplicacion # fin de cadena
    beq $t0, 10, iniciar_multiplicacion    # salto de linea (\n)
    
    subi $t0, $t0, 48         # convertir ASCII a numero
    mul $t4, $t4, 10          # desplazar decimal
    add $t4, $t4, $t0         # sumar digito
    mul $t5, $t5, 10          # aumentar el divisor (10, 100, 1000...)
    
    addi %ptr_reg, %ptr_reg, 1
    j loop_ascii

iniciar_multiplicacion:
    # PASO 2: Algoritmo de multiplicaciones sucesivas
    # t4 = valor fraccionario entero (75)
    # t5 = el divisor (100)
loop_bits:
    beq $t2, 8, fin_fraccion  # detenerse al llegar a 8 bits 
    
    sll %reg_res_frac, %reg_res_frac, 1 # espacio para el nuevo bit
    mul $t4, $t4, 2           # multiplicar por 2
    
    blt $t4, $t5, bit_cero    # si resultado < divisor, el bit es 0
    
    # si resultado >= divisor, el bit es 1
    ori %reg_res_frac, %reg_res_frac, 1
    sub $t4, $t4, $t5         # restar el "entero" (el divisor)
    
bit_cero:
    addi $t2, $t2, 1          # incrementar contador de bits
    j loop_bits

fin_fraccion:
.end_macro

.macro m_ImprimirBinario(%reg_datos)
    li $t6, 32          # contador para los 32 bits [cite: 18]
    move $t7, %reg_datos # copia para no destruir el original
    
loop_bin:
    beqz $t6, fin_m_bin
    rol $t7, $t7, 1     # rotar a la izquierda para poner el bit MSB en el LSB
    andi $a0, $t7, 1    # aislar el bit actual
    addi $a0, $a0, 48   # convertir 0 o 1 a su ASCII ('0' o '1')
    
    li $v0, 11          # syscall 11: Imprimir caracter [cite: 35]
    syscall
    
    subi $t6, $t6, 1
    j loop_bin
    
fin_m_bin:
.end_macro

.macro m_ImprimirFraccionBinaria(%reg_frac)
    li $v0, 11
    li $a0, 46              # Carga el ASCII del punto '.'
    syscall                 # Imprime el punto decimal

    li $t6, 8               # Vamos a imprimir exactamente 8 bits 
    move $t7, %reg_frac 
    sll $t7, $t7, 24        # Movemos los 8 bits al inicio (MSB) para imprimirlos de izq a der

loop_frac_bin:
    beqz $t6, fin_frac_bin
    rol $t7, $t7, 1         # Rota el bit hacia la derecha
    andi $a0, $t7, 1        # Aísla el bit
    addi $a0, $a0, 48       # Convierte a ASCII ('0' o '1')
    
    li $v0, 11
    syscall
    
    subi $t6, $t6, 1
    j loop_frac_bin
fin_frac_bin:
.end_macro

.macro m_ImprimirHex(%reg_datos)
    li $t6, 8           # 8 grupos de 4 bits = 32 bits
    move $t7, %reg_datos
    
loop_hex:
    beqz $t6, fin_m_hex
    rol $t7, $t7, 4     # rotar 4 bits a la izquierda
    andi $t0, $t7, 0xF  # mascara para obtener solo los 4 bits de la derecha
    
    ble $t0, 9, es_numero
    addi $t0, $t0, 7    # ajuste para letras (A-F) en la tabla ASCII
es_numero:
    addi $a0, $t0, 48   # convertir a ASCII
    
    li $v0, 11          # syscall 11: Imprimir caracter
    syscall
    
    subi $t6, $t6, 1
    j loop_hex
    
fin_m_hex:
.end_macro

# string a pivote
# macro para convertir un string en base a 10 a un entero (complemento a 2)
.macro m_Base10_A_Entero(%ptr_buffer, %reg_resultado)
    li %reg_resultado, 0	# inicia el resultado en 0
    li $t9, 10			# guarda la base 10 para las multiplicaciones
    
loop_b10:
    lbu $t8, 0(%ptr_buffer)	# lee un caracter del string ingresado
    beq $t8, 10, fin_b10	# si es un Enter (\n), termina de 
    beq $t8, 0, fin_b10		# si es el carácter nulo (fin), termina de leer
    beq $t8, 46, fin_b10
    beq $t8, 43, sig_b10	# si es '+' lo ignora y pasa al siguiente
    beq $t8, 45, sig_b10 	# si es '-' lo ignora y pasa al siguiente
    blt $t8, 48, sig_b10	# si el caracter es menor a '0' lo ignora
    bgt $t8, 57, sig_b10	# si el carácter es mayor a '9', es basura y lo ignora
    # resultado = (resultado * 10) + nuevo digito
    subi $t8, $t8, 48		# convierte de ASCII a digito real (0-9)
    mul %reg_resultado, %reg_resultado, $t9	# multiplica el acumulado por 10
    add %reg_resultado, %reg_resultado, $t8	# suma el nuevo digito al acumulado
    
sig_b10:
    addi %ptr_buffer, %ptr_buffer, 1	# pasa al siguiente caracter
    j loop_b10				# repite
    
fin_b10:
.end_macro


.macro m_Bin_A_Entero(%ptr_buffer, %reg_resultado)
    li %reg_resultado, 0     # inicializa el resultado
loop_b_read:
    lbu $t8, 0(%ptr_buffer)  # carga caracter
    beq $t8, 10, fin_b_read  # salida por Enter
    beq $t8, 0, fin_b_read   # salida por caracter nulo
    
    blt $t8, 48, sig_b_read  # ignora caracteres menores a '0'
    bgt $t8, 49, sig_b_read  # ignora caracteres mayores a '1' (es binario)
    
    subi $t8, $t8, 48        # convierte de ASCII a numero real (0 o 1)
    sll %reg_resultado, %reg_resultado, 1   # multiplica por 2 desplazando los bits a la izquierda
    add %reg_resultado, %reg_resultado, $t8 # suma el nuevo bit al final
sig_b_read:
    addi %ptr_buffer, %ptr_buffer, 1 # avanza al siguiente caracter
    j loop_b_read
fin_b_read:
.end_macro

.macro m_Hex_A_Entero(%ptr_buffer, %reg_resultado)
    li %reg_resultado, 0     # inicia en 0
loop_h_read:
    lbu $t8, 0(%ptr_buffer)
    beq $t8, 10, fin_h_read  # salida por enter
    beq $t8, 0, fin_h_read   # salida por nulo
    
    beq $t8, 43, sig_h_read  # ignorar '+'
    beq $t8, 45, sig_h_read  # ignorar '-'
    
    bge $t8, 48, chk_n       # verifica si es mayor o igual a '0'
    j sig_h_read             # si es menor lo ignora
chk_n:
    ble $t8, 57, is_n        # si es menor/igual a '9', es un numero valido (0-9)
    bge $t8, 65, chk_u       # si es mayor o igual a 'A', revisa letras mayusculas
chk_u:
    ble $t8, 70, is_u        # si es menor/igual a 'F', es una letra valida (A-F)
    bge $t8, 97, chk_l       # si es mayor o igual a 'a', revisa minusculas
chk_l:
    ble $t8, 102, is_l       # si es menor/igual a 'f', es valida (a-f)
    j sig_h_read             # si no cae en ningún rango, es basura y lo ignora
is_n:
    subi $t8, $t8, 48        # convierte ASCII '0'-'9' a valor 0-9
    j add_h
is_u:
    subi $t8, $t8, 55        # convierte ASCII 'A'-'F' a valor 10-15
    j add_h
is_l:
    subi $t8, $t8, 87        # convierte ASCII 'a'-'f' a valor 10-15
add_h:
    sll %reg_resultado, %reg_resultado, 4   # multiplica acumulado por 16 (desplaza 4 bits)
    add %reg_resultado, %reg_resultado, $t8 # suma el valor hexadecimal
sig_h_read:
    addi %ptr_buffer, %ptr_buffer, 1
    j loop_h_read
fin_h_read:
.end_macro

.macro m_Octal_A_Entero(%ptr_buffer, %reg_resultado)
    li %reg_resultado, 0
loop_o_read:
    lbu $t8, 0(%ptr_buffer)
    beq $t8, 10, fin_o_read
    beq $t8, 0, fin_o_read
    
    beq $t8, 43, sig_o_read  # ignorar '+'
    beq $t8, 45, sig_o_read  # ignorar '-'
    
    blt $t8, 48, sig_o_read  # ignora menores a '0'
    bgt $t8, 55, sig_o_read  # ignora mayores a '7' (solo llega hasta 7)
    
    subi $t8, $t8, 48        # ASCII a numero real (0-7)
    sll %reg_resultado, %reg_resultado, 3   # multiplica acumulado por 8 (desplaza 3 bits)
    add %reg_resultado, %reg_resultado, $t8 # suma el nuevo digito octal
sig_o_read:
    addi %ptr_buffer, %ptr_buffer, 1
    j loop_o_read
fin_o_read:
.end_macro

.macro m_ImprimirBase10(%reg_valor)
    bgez %reg_valor, b10_pos # verifica si el numero es positivo (mayor o igual a cero)
    
    # si es negativo:
    li $a0, 45               # carga el signo '-'
    li $v0, 11               # imprime el signo
    syscall
    mul %reg_valor, %reg_valor, -1 # vuelve el numero positivo para hacer las divisiones
    j b10_proc               # salta a procesarlo
b10_pos:
    # si es positivo:
    li $a0, 43               # carga el signo '+'
    li $v0, 11               # imprime el '+'
    syscall
b10_proc:
    move $t0, %reg_valor     # copia el numero
    li $t1, 10               # constante 10 (divisor)
    li $t2, 0                # contador de digitos extraidos
l_div10:
    div $t0, $t1             # divide el numero entre 10
    mflo $t0                 # el cociente se guarda para seguir dividiendolo
    mfhi $t3                 # el residuo es el digito extraido 
    
    addi $sp, $sp, -4        # hace espacio de 4 bytes en la pila de memoria (Stack)
    sw $t3, 0($sp)           # guarda el digito (residuo) en la pila
    addi $t2, $t2, 1         # incrementa el contador de digitos
    bgtz $t0, l_div10        # si el cociente es mayor a 0 repite la division

l_imp10:
    # bucle para sacar los digitos de la pila e imprimirlos (saldran al derecho)
    lw $t3, 0($sp)           # recupera un digito de la pila
    addi $sp, $sp, 4         # restaura la memoria de la pila
    addi $a0, $t3, 48        # convierte el digito numerico a su ASCII respectivo
    li $v0, 11               # syscall para imprimir el digito
    syscall
    subi $t2, $t2, 1         # disminuye el contador de digitos pendientes
    bgtz $t2, l_imp10        # si quedan digitos repite
.end_macro
	 
.macro m_ImprimirOctal(%reg_valor)
    # misma logica de Base 10, pero usando 8 como divisor
    bgez %reg_valor, oct_pos
    li $a0, 45               # signo '-'
    li $v0, 11
    syscall
    mul %reg_valor, %reg_valor, -1 # lo vuelve positivo
    j oct_proc
oct_pos:
    li $a0, 43               # signo '+'
    li $v0, 11
    syscall
oct_proc:
    move $t0, %reg_valor
    li $t1, 8                # constante 8 (divisor base octal)
    li $t2, 0                # contador de digitos en pila
l_div8:
    div $t0, $t1             # divide entre 8
    mflo $t0                 # nuevo cociente
    mfhi $t3                 # residuo (digito octal)
    addi $sp, $sp, -4        # reserva memoria en pila
    sw $t3, 0($sp)           # guarda digito en pila
    addi $t2, $t2, 1         # suma al contador
    bgtz $t0, l_div8         # si hay cociente repite
l_imp8:
    lw $t3, 0($sp)           # caca el digito de la pila
    addi $sp, $sp, 4         # libera memoria
    addi $a0, $t3, 48        # convierte a ASCII
    li $v0, 11               # imprime el numero octal
    syscall
    subi $t2, $t2, 1         # resta contador
    bgtz $t2, l_imp8         # repite hasta vaciar la pila
.end_macro
	
	
.data
	Mensaje1: .asciiz "\nQue formato numerico quieres usar:\n(a=decimal empaquetado, b=Complemento a 2, c=Base 10, d=Octal, e=Hexadecimal): "
	Mensaje2:  .asciiz "Que formato quiere convertirlo:  (decimal empaquetado =a,  Complemento a 2=b, Base 10 = c, Octal = d y Hexadecimal =e): "
	MensajeError: .asciiz "\n[!] ERROR: El formato de origen y destino no pueden ser iguales. Intente de nuevo.\n" # <-- NUEVO MENSAJE
	Num1: .asciiz "Introduce el número: " 
	Num2: .asciiz "\nEl numero convertido es: "
	Buffer1: .space 20 #Almacena la primera opcion
	Buffer2: .space 20 #Almacena la segunda opcion
	BufferCon: .space 64 #para el numero a convertir
.text
main:

#Muestra el mensaje1/ Pidiendo el formato de origen
    imprimir_str(Mensaje1)
    leer_str(Buffer1, 20)
  

#Muestra el mensaje 2/ Pide el formato destino
    imprimir_str(Mensaje2)
    leer_str(Buffer2, 20)
    
    # Valida si el formato numerico es el mismo
    la $t0, Buffer1              # Carga la dirección de Buffer1
    lbu $t1, 0($t0)              # Lee el primer carácter del origen (ej: 'a')
    
    la $t2, Buffer2              # Carga la dirección de Buffer2
    lbu $t3, 0($t2)              # Lee el primer carácter del destino (ej: 'a')
    
    beq $t1, $t3, error_iguales  # Si son iguales, salta a la etiqueta de error
# ---> FIN DE VALIDACIÓN <---
   
   #Pedir el NUMERO a convertir
    imprimir_str(Num1)
    leer_str(BufferCon, 64)
    
# transfromacion
#string a pivote
    la $t0, Buffer1              # carga la direccion de Buffer1
    lbu $t1, 0($t0)              # lee la primera letra del buffer de origen ('a', 'b', etc.)
    la $a1, BufferCon            # carga la direccion donde esta el numero 
    
    # compara la letra origen y salta a la seccion correcta
    beq $t1, 'b', origen_binario
    beq $t1, 'c', origen_base10
    beq $t1, 'd', origen_octal
    beq $t1, 'e', origen_hexadecimal
    j procesar_destino           # si es 'a' o erroneo va directo al destino para evitar fallas

origen_binario:
    m_Bin_A_Entero($a1, $s0)     # convierte de string binario y deja el numero en $s0
    j procesar_destino           # termino va al destino

origen_base10:
    m_ProcesarSigno($a1, $s1)    # detecta el signo (+ o -) guarda estado en $s1
    m_Base10_A_Entero($a1, $s0)  # convierte la parte entera y se detiene si hay un '.'
    
    li $s2, 0                    # inicializamos la fracción en 0 por defecto
    lbu $t0, 0($a1)              # leemos dónde se detuvo el puntero
    bne $t0, 46, saltar_fraccion # si NO es un '.', saltamos la conversión fraccionaria
    
    addi $a1, $a1, 1             # si es '.', avanzamos el puntero 1 espacio para saltarlo
    m_ConvertirFraccion($a1, $s2)# llamamos a tu macro. Los 8 bits se guardan en $s2

saltar_fraccion:
    beqz $s1, procesar_destino   # si $s1 es 0 (positivo), salta a destino
    mul $s0, $s0, -1             # si era negativo multiplica por -1 el numero entero final
    j procesar_destino
origen_octal:
    m_ProcesarSigno($a1, $s1)    # detecta signo
    m_Octal_A_Entero($a1, $s0)   # convierte string octal a numero en $s0
    beqz $s1, procesar_destino   # si es positivo avanza
    mul $s0, $s0, -1             # splica negativo
    j procesar_destino

origen_hexadecimal:
    m_ProcesarSigno($a1, $s1)    # detecta signo
    m_Hex_A_Entero($a1, $s0)     # convierte string hexa a numero en $s0
    beqz $s1, procesar_destino   # si es positivo avanza
    mul $s0, $s0, -1             # aplica negativo
    j procesar_destino

   procesar_destino:
    imprimir_str(Num2)           # imprime "El numero convertido es: "

    la $t0, Buffer2              # carga la direccion de memoria de Buffer2
    lbu $t1, 0($t0)              # lee la letra ingresada como destino

    # evalua la letra de destino para usar la macro de impresion correcta
    beq $t1, 'a', destino_empaquetado
    beq $t1, 'b', destino_binario
    beq $t1, 'c', destino_base10
    beq $t1, 'd', destino_octal
    beq $t1, 'e', destino_hexadecimal
    j salir_programa             # si hubo un error o letra no valida sale del programa
    
.macro m_ImprimirEmpaquetado(%reg_valor)
    move $t0, %reg_valor
    li $t1, 0           # Aquí armaremos el número BCD empaquetado
    li $t2, 12          # 12 equivale a 'C' (1100 en binario), que es el signo POSITIVO
    
    bgez $t0, emp_pos   # Si es positivo, saltamos
    li $t2, 13          # 13 equivale a 'D' (1101 en binario), que es el signo NEGATIVO
    mul $t0, $t0, -1    # Volvemos el número positivo para poder extraer sus dígitos
    
emp_pos:
    move $t1, $t2       # Colocamos el nibble (4 bits) del signo al final del registro
    li $t3, 4           # Contador de desplazamiento (arranca en 4 para no pisar el signo)
    li $t4, 10          # Divisor para extraer dígitos base 10
    
loop_emp:
    beqz $t0, fin_emp_build # Si ya no quedan dígitos que procesar, terminamos
    div $t0, $t4
    mflo $t0            # Guardamos el cociente
    mfhi $t5            # El residuo es el dígito actual (0-9)
    
    sllv $t5, $t5, $t3  # Desplazamos los 4 bits del dígito a su posición correcta
    or $t1, $t1, $t5    # Los fusionamos en nuestro registro BCD final
    
    addi $t3, $t3, 4    # Aumentamos el desplazamiento en 4 bits para el próximo dígito
    j loop_emp
    
fin_emp_build:
    # Ahora en $t1 tenemos los 32 bits ordenados en formato Decimal Empaquetado.
    # Reutilizamos tu macro binaria para imprimir los 32 ceros y unos en pantalla.
    m_ImprimirBinario($t1)
.end_macro
destino_binario:
    m_ImprimirBinario($s0)  # manda el registro pivote a la macro binaria
    m_ImprimirFraccionBinaria($s2)       
    j salir_programa             # finaliza
    
destino_empaquetado:
    m_ImprimirEmpaquetado($s0)   # Llama a la nueva macro
    j salir_programa             # finaliza

destino_base10:
    m_ImprimirBase10($s0)        # manda el registro pivote a  macro Base 10
    j salir_programa             # finaliza

destino_octal:
    m_ImprimirOctal($s0)         # manda el registro pivote a macro Octal
    j salir_programa             # finaliza

destino_hexadecimal:
    m_ImprimirHex($s0)           # manda el pivote a la macro hexadecimal 
    j salir_programa             # finaliza
    
error_iguales:
    imprimir_str(MensajeError)   # Imprime el aviso
    j main
    
    # Sale del programa
salir_programa:
    li $v0, 10
    syscall
