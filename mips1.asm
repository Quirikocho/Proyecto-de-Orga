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
    li $t2, 0                 # Contador de bits (m�ximo 8)
    li $t3, 10                # Constante para multiplicar/dividir
    
    # PASO 1: Convertir el string de la fracci�n a un entero
    # Ej: de ".75" a 75
    li $t4, 0                 # Valor acumulado
    li $t5, 1                 # Multiplicador (potencia de 10) para el divisor
loop_ascii:
    lbu $t0, 0(%ptr_reg)
    beq $t0, $zero, iniciar_multiplicacion # Fin de cadena
    beq $t0, 10, iniciar_multiplicacion    # Salto de l�nea (\n)
    
    subi $t0, $t0, 48         # Convertir ASCII a n�mero
    mul $t4, $t4, 10          # Desplazar decimal
    add $t4, $t4, $t0         # Sumar d�gito
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

.data
	Mensaje1: .asciiz "Que formato numerico quieres usar: (decimal empaquetado =a, Complemento a 2 = b, Base 10 =c, Octal =d y Hexadecimal =e)"
	Mensaje2:  .asciiz "Que formato quiere convertirlo:  (decimal empaquetado =a,  Complemento a 2=b, Base 10 = c, Octal = d y Hexadecimal =e)"
	Num1: .asciiz "Introduce el número: " 
	Num2: .asciiz "El numero convertido es: "
	Buffer1: .space 20 #Almacena la primera opción
	Buffer2: .space 20 #Almacena la segunda opción
	BufferCon: .space 64 #para el número a convertir
.text
main:

#Muestra el mensaje1
    imprimir_str(Mensaje1)
    leer_str(Buffer1, 20)
  #Lee el mensaje 1
    li $v0, 8
    la $a0, Buffer1
    li $a1, 64
    syscall 

#Muestra el mensaje 2

    li $v0, 4
    la $a0, Mensaje2
    syscall
  #lee el mensaje 2
    li $v0, 8
    la $a0, Buffer2
    li $a1, 64
    syscall 
    #Lee el numero que vas a convertir
    li $v0, 4
    la $a0, Num1
    syscall
  
    li $v0, 8
    syscall 
    move $t2, $v0
    
    #Lee el numero que convertiste
    li $v0, 4
    la $a0, Num2
    syscall 
    
    li $v0, 8
    syscall 
    
   
    
    # Sale del programa
    li $v0, 10
    syscall
