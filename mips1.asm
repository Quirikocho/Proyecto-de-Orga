.macro imprimir_str(%label) # Macro para imprimir una cadena de caracteres
    li $v0, 4
    la $a0, %label
    syscall
.end_macro

.macro leer_str(%buffer, %size) # Macro para leer una cadena de caracteres (String)
    li $v0, 8
    la $a0, %buffer
    li $a1, %size 
    syscall
.end_macro


.macro m_ProcesarSigno(%ptr_reg, %signo_reg)
    lbu $t0, 0(%ptr_reg)    # Cargar el primer byte
    li %signo_reg, 0        # Por defecto es positivo (0)
    
    li $t1, 45              # ASCII de '-'
    beq $t0, $t1, es_negativo
    
    li $t1, 43              # ASCII de '+'
    beq $t0, $t1, es_positivo
    j fin_macro             # Si no hay signo, no avanzamos el puntero
    
es_negativo:
    li %signo_reg, 1        # Marcar como negativo
es_positivo:
    addi %ptr_reg, %ptr_reg, 1 # Avanzar el puntero para saltar el signo
    
fin_macro:
.end_macro


.macro m_AplicarComplemento2(%reg_valor)
    not %reg_valor, %reg_valor  # Invertir todos los bits (Bitwise NOT)
    addi %reg_valor, %reg_valor, 1 # Sumar 1
.end_macro


.macro m_ConvertirFraccion(%ptr_reg, %reg_res_frac)
    # %ptr_reg: Puntero al string despues del '.'
    # %reg_res_frac: Registro donde guardaremos los 8 bits
    
    li %reg_res_frac, 0       # Limpiar el resultado
    li $t2, 0                 # Contador de bits (máximo 8)
    li $t3, 10                # Constante para multiplicar/dividir
    
    # PASO 1: Convertir el string de la fracción a un entero
    # Ej: de ".75" a 75
    li $t4, 0                 # Valor acumulado
    li $t5, 1                 # Multiplicador (potencia de 10) para el divisor
loop_ascii:
    lbu $t0, 0(%ptr_reg)
    beq $t0, $zero, iniciar_multiplicacion # Fin de cadena
    beq $t0, 10, iniciar_multiplicacion    # Salto de línea (\n)
    
    subi $t0, $t0, 48         # Convertir ASCII a número
    mul $t4, $t4, 10          # Desplazar decimal
    add $t4, $t4, $t0         # Sumar dígito
    mul $t5, $t5, 10          # Aumentar el divisor (10, 100, 1000...)
    
    addi %ptr_reg, %ptr_reg, 1
    j loop_ascii

iniciar_multiplicacion:
    # PASO 2: Algoritmo de multiplicaciones sucesivas
    # t4 = valor fraccionario entero (75)
    # t5 = el divisor (100)
loop_bits:
    beq $t2, 8, fin_fraccion  # Detenerse al llegar a 8 bits 
    
    sll %reg_res_frac, %reg_res_frac, 1 # Espacio para el nuevo bit
    mul $t4, $t4, 2           # Multiplicar por 2
    
    blt $t4, $t5, bit_cero    # Si resultado < divisor, el bit es 0
    
    # Si resultado >= divisor, el bit es 1
    ori %reg_res_frac, %reg_res_frac, 1
    sub $t4, $t4, $t5         # Restar el "entero" (el divisor)
    
bit_cero:
    addi $t2, $t2, 1          # Incrementar contador de bits
    j loop_bits

fin_fraccion:
.end_macro

.macro m_ImprimirBinario(%reg_datos)
    li $t6, 32          # Contador para los 32 bits [cite: 18]
    move $t7, %reg_datos # Copia para no destruir el original
    
loop_bin:
    beqz $t6, fin_m_bin
    rol $t7, $t7, 1     # Rotar a la izquierda para poner el bit MSB en el LSB
    andi $a0, $t7, 1    # Aislar el bit actual
    addi $a0, $a0, 48   # Convertir 0 o 1 a su ASCII ('0' o '1')
    
    li $v0, 11          # Syscall 11: Imprimir carácter [cite: 35]
    syscall
    
    subi $t6, $t6, 1
    j loop_bin
    
fin_m_bin:
.end_macro


.macro m_ImprimirHex(%reg_datos)
    li $t6, 8           # 8 grupos de 4 bits = 32 bits
    move $t7, %reg_datos
    
loop_hex:
    beqz $t6, fin_m_hex
    rol $t7, $t7, 4     # Rotar 4 bits a la izquierda
    andi $t0, $t7, 0xF  # Máscara para obtener solo los 4 bits de la derecha
    
    ble $t0, 9, es_numero
    addi $t0, $t0, 7    # Ajuste para letras (A-F) en la tabla ASCII
es_numero:
    addi $a0, $t0, 48   # Convertir a ASCII
    
    li $v0, 11          # Syscall 11: Imprimir carácter
    syscall
    
    subi $t6, $t6, 1
    j loop_hex
    
fin_m_hex:
.end_macro

.data
	Mensaje1: .asciiz "\nQue formato numerico quieres usar:\n(a=decimal empaquetado, b=Complemento a 2, c=Base 10, d=Octal, e=Hexadecimal): "
	Mensaje2:  .asciiz "Que formato quiere convertirlo:  (decimal empaquetado =a,  Complemento a 2=b, Base 10 = c, Octal = d y Hexadecimal =e): "
	Num1: .asciiz "Introduce el nÃºmero: " 
	Num2: .asciiz "\nEl numero convertido es: "
	Buffer1: .space 20 #Almacena la primera opciÃ³n
	Buffer2: .space 20 #Almacena la segunda opciÃ³n
	BufferCon: .space 64 #para el nÃºmero a convertir
.text
main:

#Muestra el mensaje1/ Pidiendo el formato de origen
    imprimir_str(Mensaje1)
    leer_str(Buffer1, 20)
  

#Muestra el mensaje 2/ Pide el formato destino
    imprimir_str(Mensaje2)
    leer_str(Buffer1, 20)
   
   #Pedir el NÃšMERO a convertir
    imprimir_str(Num1)
    leer_str(BufferCon, 64)
    

#Lee el numero que vas a convertir
   
   #Muestra el resultado
    imprimir_str(Num2)
    
    # Sale del programa
    li $v0, 10
    syscall
