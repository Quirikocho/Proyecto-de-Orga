#################################
#MACROS
#################################
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

.macro m_ProcesarSigno(%ptr_reg, %signo_reg) # Procesa y guarda el signo del numero (+ o -)
    lbu $t0, 0(%ptr_reg)   
    li %signo_reg, 0        
    
    li $t1, 45              
    beq $t0, $t1, es_negativo
    
    li $t1, 43             
    beq $t0, $t1, es_positivo
    j fin_macro            
    
es_negativo:
    li %signo_reg, 1        
es_positivo:
    addi %ptr_reg, %ptr_reg, 1 
    
fin_macro:
.end_macro

.macro m_AplicarComplemento2(%reg_valor) # Aplica complemento a 2
    not %reg_valor, %reg_valor  
    addi %reg_valor, %reg_valor, 1 
.end_macro

.macro m_ConvertirFraccion(%ptr_reg, %reg_res_frac) # Convierte la parte decimal a fraccion binaria (8 bits)
    li %reg_res_frac, 0     
    li $t2, 0                 
    li $t3, 10              
    li $t4, 0            
    li $t5, 1               
    
loop_ascii: #Lee los caracteres decimales y arma un numero entero que servira de base para la fraccion
    lbu $t0, 0(%ptr_reg)
    beq $t0, $zero, iniciar_multiplicacion 
    beq $t0, 10, iniciar_multiplicacion   
    
    subi $t0, $t0, 48       
    mul $t4, $t4, 10       
    add $t4, $t4, $t0         
    mul $t5, $t5, 10          
    
    addi %ptr_reg, %ptr_reg, 1
    j loop_ascii

iniciar_multiplicacion:
    # Aplica multiplicaciones sucesivas
 
loop_bits: #Loop que realiza las multiplicaciones sucesivas 
    beq $t2, 8, fin_fraccion  
    
    sll %reg_res_frac, %reg_res_frac, 1 
    mul $t4, $t4, 2           
    
    blt $t4, $t5, bit_cero  
  
    ori %reg_res_frac, %reg_res_frac, 1
    sub $t4, $t4, $t5         
    
bit_cero:
    addi $t2, $t2, 1      
    j loop_bits

fin_fraccion:
.end_macro

.macro m_ImprimirBinario(%reg_datos) # Imprime un registro en formato binario (32 bits)
    li $t6, 32          
    move $t7, %reg_datos 
    
loop_bin:    #Rota el registro bit a bit 32 veces, aislando e imprimiendo cada uno
    beqz $t6, fin_m_bin
    rol $t7, $t7, 1     
    andi $a0, $t7, 1    
    addi $a0, $a0, 48  
    
    li $v0, 11       
    syscall
    
    subi $t6, $t6, 1
    j loop_bin
    
fin_m_bin:
.end_macro

.macro m_ImprimirFraccionBinaria(%reg_frac) #Macro que imprime el punto decimal y los 8 bits de la fraccion
    li $v0, 11
    li $a0, 46            
    syscall               

    li $t6, 8              
    move $t7, %reg_frac 
    sll $t7, $t7, 24        

loop_frac_bin: #Rota y aisla 8 veces para imprimir los bits decimales calculados
    beqz $t6, fin_frac_bin
    rol $t7, $t7, 1         
    andi $a0, $t7, 1        
    addi $a0, $a0, 48      
    
    li $v0, 11
    syscall
    
    subi $t6, $t6, 1
    j loop_frac_bin
fin_frac_bin:
.end_macro

.macro m_ImprimirHex(%reg_datos) #Macro que Imprime el valor en formato Hexadecimal antecedido por su signo
    move $t7, %reg_datos
    bgez $t7, hex_pos
    li $a0, 45          # Imprimir '-'
    li $v0, 11
    syscall
    mul $t7, $t7, -1    # Volver positivo para imprimir la magnitud
    j hex_proc
hex_pos:
    li $a0, 43          # Imprimir '+'
    li $v0, 11
    syscall
hex_proc:
    li $t6, 8           # 8 caracteres (32 bits)
loop_hex:  #Procesa el registro en 8 bloques de 4 bits (nibbles) para convertirlos a letras/numeros base 16
    beqz $t6, fin_m_hex
    rol $t7, $t7, 4    
    andi $t0, $t7, 0xF  
    
    ble $t0, 9, es_numero
    addi $t0, $t0, 7   
es_numero:
    addi $a0, $t0, 48  
    li $v0, 11         
    syscall
    
    subi $t6, $t6, 1
    j loop_hex
fin_m_hex:
.end_macro

.macro m_Base10_A_Entero(%ptr_buffer, %reg_resultado) # macro para convertir un string en base a 10 a un entero (complemento a 2)
    li %reg_resultado, 0	
    li $t9, 10			
    
loop_b10:  # Recorre el string multiplicando por 10 y sumando el nuevo digito hasta encontrar un nulo, salto o punto
    lbu $t8, 0(%ptr_buffer)	
    beq $t8, 10, fin_b10	 
    beq $t8, 0, fin_b10		
    beq $t8, 46, fin_b10
    beq $t8, 43, sig_b10	
    beq $t8, 45, sig_b10 	
    blt $t8, 48, sig_b10	
    bgt $t8, 57, sig_b10	
    subi $t8, $t8, 48		
    mul %reg_resultado, %reg_resultado, $t9	
    add %reg_resultado, %reg_resultado, $t8	
    
sig_b10:
    addi %ptr_buffer, %ptr_buffer, 1	# pasa al siguiente caracter
    j loop_b10				# repite
    
fin_b10:
.end_macro

.macro m_Bin_A_Entero(%ptr_buffer, %reg_resultado) #Transforma un texto binario (ceros y unos) a un valor numerico
    li %reg_resultado, 0    
loop_b_read: #Ciclo que desplaza los bits a la izquierda (x2) e inserta el nuevo bit leido del string
    lbu $t8, 0(%ptr_buffer) 
    beq $t8, 10, fin_b_read  
    beq $t8, 0, fin_b_read   
    
    blt $t8, 48, sig_b_read  
    bgt $t8, 49, sig_b_read  
    
    subi $t8, $t8, 48        
    sll %reg_resultado, %reg_resultado, 1   
    add %reg_resultado, %reg_resultado, $t8 
sig_b_read:
    addi %ptr_buffer, %ptr_buffer, 1 
    j loop_b_read
fin_b_read:
.end_macro

.macro m_Hex_A_Entero(%ptr_buffer, %reg_resultado) #Macro que transforma una cadena Hexadecimal a un valor numerico
    li %reg_resultado, 0   
loop_h_read: #Loop que lee caracteres (0-9, A-F, a-f), multiplica el acumulado por 16 y suma el nuevo valor
    lbu $t8, 0(%ptr_buffer)
    beq $t8, 10, fin_h_read  
    beq $t8, 0, fin_h_read   
    
    beq $t8, 43, sig_h_read  
    beq $t8, 45, sig_h_read  
    
    bge $t8, 48, chk_n       
    j sig_h_read            
chk_n:
    ble $t8, 57, is_n        
    bge $t8, 65, chk_u       
chk_u:
    ble $t8, 70, is_u       
    bge $t8, 97, chk_l       
chk_l:
    ble $t8, 102, is_l      
    j sig_h_read             
is_n:
    subi $t8, $t8, 48        
    j add_h
is_u:
    subi $t8, $t8, 55        
    j add_h
is_l:
    subi $t8, $t8, 87       
add_h:
    sll %reg_resultado, %reg_resultado, 4   
    add %reg_resultado, %reg_resultado, $t8 
sig_h_read:
    addi %ptr_buffer, %ptr_buffer, 1
    j loop_h_read
fin_h_read:
.end_macro

.macro m_Octal_A_Entero(%ptr_buffer, %reg_resultado) #Macro que transforma una cadena Octal a un valor numerico
    li %reg_resultado, 0
loop_o_read: #Loop que recorre los numeros (0-7), multiplica el acumulado por 8 y suma el valor
    lbu $t8, 0(%ptr_buffer)
    beq $t8, 10, fin_o_read
    beq $t8, 0, fin_o_read
    
    beq $t8, 43, sig_o_read 
    beq $t8, 45, sig_o_read  
    
    blt $t8, 48, sig_o_read  
    bgt $t8, 55, sig_o_read  
    
    subi $t8, $t8, 48        
    sll %reg_resultado, %reg_resultado, 3   
    add %reg_resultado, %reg_resultado, $t8 
sig_o_read:
    addi %ptr_buffer, %ptr_buffer, 1
    j loop_o_read
fin_o_read:
.end_macro

.macro m_Emp_A_Entero(%ptr_buffer, %reg_resultado, %reg_signo) #Macro para transformar un decimal Empaquetado a un valor numerico
    li $t0, 0               
loop_read_emp: #Ciclo que Agrupa todos los 32 bits del string crudo descartando los espacios en blanco
    lbu $t8, 0(%ptr_buffer)
    beq $t8, 10, fin_read_emp
    beq $t8, 0, fin_read_emp
    
    blt $t8, 48, sig_read_emp   
    bgt $t8, 49, sig_read_emp
    
    subi $t8, $t8, 48
    sll $t0, $t0, 1         
    add $t0, $t0, $t8       
sig_read_emp:
    addi %ptr_buffer, %ptr_buffer, 1
    j loop_read_emp
    
fin_read_emp:
    andi $t1, $t0, 0xF      
    li %reg_signo, 0        
    beq $t1, 12, es_pos_emp 
    li %reg_signo, 1       
es_pos_emp:
    srl $t0, $t0, 4         
   
    li %reg_resultado, 0    
    li $t2, 1              
    
loop_calc_emp: #Segundo ciclo de la macro; Extrae bloques de 4 bits de derecha a izquierda multiplicandolos por su valor posicional
    beqz $t0, fin_calc_emp  
    
    andi $t4, $t0, 0xF      
    mul $t4, $t4, $t2       
    add %reg_resultado, %reg_resultado, $t4
    
    mul $t2, $t2, 10       
    srl $t0, $t0, 4         
    j loop_calc_emp
    
fin_calc_emp:
.end_macro
.macro m_ImprimirBase10(%reg_valor) #Macro que imprime el numero en Base 10 extrayendo y apilando sus digitos
    bgez %reg_valor, b10_pos 
   
    li $a0, 45              
    li $v0, 11             
    syscall
    mul %reg_valor, %reg_valor, -1 
    j b10_proc            
b10_pos:
    li $a0, 43               
    li $v0, 11               
    syscall
b10_proc:
    move $t0, %reg_valor    
    li $t1, 10              
    li $t2, 0              
l_div10:
    div $t0, $t1             
    mflo $t0                 
    mfhi $t3                
    
    addi $sp, $sp, -4       
    sw $t3, 0($sp)           
    addi $t2, $t2, 1        
    bgtz $t0, l_div10        

l_imp10: # bucle para sacar los digitos de la pila e imprimirlos (saldran al derecho)
    
    lw $t3, 0($sp)           
    addi $sp, $sp, 4        
    addi $a0, $t3, 48      
    li $v0, 11               
    syscall
    subi $t2, $t2, 1         
    bgtz $t2, l_imp10        
.end_macro
	 
.macro m_ImprimirOctal(%reg_valor) #Macro que Imprime el numero en Octal apilando divisiones entre 8
    bgez %reg_valor, oct_pos
    li $a0, 45             
    li $v0, 11
    syscall
    mul %reg_valor, %reg_valor, -1 
    j oct_proc
oct_pos:
    li $a0, 43               
    li $v0, 11
    syscall
oct_proc:
    move $t0, %reg_valor
    li $t1, 8                
    li $t2, 0               
l_div8:   #Ciclo el cual divide el numero entre 8 y apila los residuos
    div $t0, $t1             
    mflo $t0                
    mfhi $t3                 
    addi $sp, $sp, -4       
    sw $t3, 0($sp)           
    addi $t2, $t2, 1         
    bgtz $t0, l_div8         
l_imp8: #Ciclo el cual Desapila los digitos y los imprime
    lw $t3, 0($sp)           
    addi $sp, $sp, 4         
    addi $a0, $t3, 48        
    li $v0, 11              
    syscall
    subi $t2, $t2, 1         
    bgtz $t2, l_imp8        
.end_macro

.macro m_ImprimirEmpaquetado(%reg_valor) #Macro que Imprime el numero en el estandar BCD (Decimal Empaquetado)
    move $t0, %reg_valor
    li $t1, 0           
    li $t2, 12          
    
    bgez $t0, emp_pos   
    li $t2, 13          
    mul $t0, $t0, -1    
    
emp_pos:
    move $t1, $t2       
    li $t3, 4          
    li $t4, 10          
    
loop_emp:  #Ciclo que divide entre 10, toma el digito, y lo incrusta en el registro en bloques de 4 bits (nibbles)
    beqz $t0, fin_emp_build 
    div $t0, $t4
    mflo $t0            
    mfhi $t5            
    
    sllv $t5, $t5, $t3  
    or $t1, $t1, $t5    
    
    addi $t3, $t3, 4    
    j loop_emp
    
fin_emp_build:
    # Ahora en $t1 tenemos los 32 bits ordenados en formato Decimal Empaquetado.
    # Reutilizamos tu macro binaria para imprimir los 32 ceros y unos en pantalla.
    m_ImprimirBinario($t1)
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
  	 li $s2, 0
#Muestra el mensaje1/ Pidiendo el formato de origen
    imprimir_str(Mensaje1)
    leer_str(Buffer1, 20)
  

#Muestra el mensaje 2/ Pide el formato destino
    imprimir_str(Mensaje2)
    leer_str(Buffer2, 20)
    
    # Valida si el formato numerico es el mismo
    la $t0, Buffer1             
    lbu $t1, 0($t0)            
    
    la $t2, Buffer2              
    lbu $t3, 0($t2)             
    
    beq $t1, $t3, error_iguales  # Si son iguales, salta a la etiqueta de error
   
   #Pedir el NUMERO a convertir
    imprimir_str(Num1)
    leer_str(BufferCon, 64)
    
# transfromacion
#string a pivote
    la $t0, Buffer1             
    lbu $t1, 0($t0)              
    la $a1, BufferCon            
    
    # compara la letra origen y salta a la seccion correcta
    beq $t1, 'a', origen_empaquetado
    beq $t1, 'b', origen_binario
    beq $t1, 'c', origen_base10
    beq $t1, 'd', origen_octal
    beq $t1, 'e', origen_hexadecimal
    j procesar_destino          

origen_empaquetado: 
    m_Emp_A_Entero($a1, $s0, $s1) # Llama a la macro y guarda numero en $s0 y signo en $s1
    beqz $s1, procesar_destino   
    mul $s0, $s0, -1              
    j procesar_destino #Procesa hacia el destino


origen_binario:  #Llama a la macro binaria y guarda el numero
    m_Bin_A_Entero($a1, $s0)     
    
    j procesar_destino           # termino va al destino

origen_base10: #Llama a la macro base10 y guarda el numero
    m_ProcesarSigno($a1, $s1)   
    m_Base10_A_Entero($a1, $s0) 
    
    li $s2, 0                    
    lbu $t0, 0($a1)             
    bne $t0, 46, saltar_fraccion 
    
    addi $a1, $a1, 1            
    m_ConvertirFraccion($a1, $s2)# llamamos a tu macro. Los 8 bits se guardan en $s2

saltar_fraccion:
    beqz $s1, procesar_destino   
    mul $s0, $s0, -1             
    j procesar_destino
    
origen_octal:  #Llama a la macro octal y guarda el numero
    m_ProcesarSigno($a1, $s1)    
    m_Octal_A_Entero($a1, $s0)   
    beqz $s1, procesar_destino   
    mul $s0, $s0, -1           
    j procesar_destino

origen_hexadecimal: #Llama a la macro hexadecimal y guarda el numero
    m_ProcesarSigno($a1, $s1)    
    m_Hex_A_Entero($a1, $s0)    
    beqz $s1, procesar_destino   
    mul $s0, $s0, -1             
    j procesar_destino

   procesar_destino:
    imprimir_str(Num2)           # imprime "El numero convertido es: "

    la $t0, Buffer2              # carga la direccion de memoria de Buffer2
    lbu $t1, 0($t0)             

    # evalua la letra de destino para usar la macro de impresion correcta
    beq $t1, 'a', destino_empaquetado
    beq $t1, 'b', destino_binario
    beq $t1, 'c', destino_base10
    beq $t1, 'd', destino_octal
    beq $t1, 'e', destino_hexadecimal
    j salir_programa             # si hubo un error o letra no valida sale del programa
    
destino_binario:
    m_ImprimirBinario($s0)  # manda el registro pivote a la macro binaria
    beqz $s2, salir_programa
    m_ImprimirFraccionBinaria($s2)       
    j salir_programa          
    
destino_empaquetado:
    m_ImprimirEmpaquetado($s0)   # Llama a la nueva macro
    j salir_programa           

destino_base10:
    m_ImprimirBase10($s0)        # manda el registro pivote a  macro Base 10
    j salir_programa             

destino_octal:
    m_ImprimirOctal($s0)         # manda el registro pivote a macro Octal
    j salir_programa            

destino_hexadecimal:
    m_ImprimirHex($s0)           # manda el pivote a la macro hexadecimal 
    j salir_programa            
    
error_iguales:
    imprimir_str(MensajeError)   # Imprime el aviso de que la letra origen es igual a la de origen
    j main
    
    # Sale del programa
salir_programa:
    li $v0, 10
    syscall
