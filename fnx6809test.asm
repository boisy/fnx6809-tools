zeropage       equ       0
start          equ       $e000
vectors        equ       $fff0

               org       zeropage
mmu_ctrl       rmb       1
io_ctrl        rmb       1
               rmb       $20-.
next_char      rmb       2

               org       start

; X = cursor (for hack)
; Y = PC
; U = context SP
; S = CPU's SP

main                     
reset                    
               orcc      #$50                ; Turn off interrupts
               lds       #$01ff

               jsr       init_display

               lda       #2
               sta       io_ctrl
               ldx       #$c000
               stx       next_char

               leax      hello,pcr
               jsr       putstr

setupirq
               lda       #0
               sta       io_ctrl
               lda       #$FE
               sta       $D66C
               lda       #$FF
               sta       $D660
               lda       #2
               sta       io_ctrl
forever                  
               cwai      #^$50
               bra       forever

handleirq      lda       #2
               sta       io_ctrl
               inc       ,x
               lda       #0
               sta       io_ctrl
               lda       #$01
               sta       $D660
               lda       #2
               sta       io_ctrl
               rti       
 
swi                      
               ldx       #$C000
               bra       handleirq
               
swi2                     
               ldx       #$C001
               bra       handleirq


swi3                     
               ldx       #$C002
               bra       handleirq

irq                      
               ldx       #$C003
               bra       handleirq

firq                     
               ldx       #$C004
               bra       handleirq

nmi                      
               ldx       #$C005
               bra       handleirq

hello          .strz                         "IRQ/FIRQ/NMI Test"


MASTER_CTRL_REG_L =         $D000
;Control Bits Fields
Mstr_Ctrl_Text_Mode_En =         $01                 ; Enable the Text Mode
Mstr_Ctrl_Text_Overlay =         $02                 ; Enable the Overlay of the text mode on top of Graphic Mode (the Background Color is ignored)
Mstr_Ctrl_Graph_Mode_En =         $04                 ; Enable the Graphic Mode
Mstr_Ctrl_Bitmap_En =         $08                 ; Enable the Bitmap Module In Vicky
Mstr_Ctrl_TileMap_En =         $10                 ; Enable the Tile Module in Vicky
Mstr_Ctrl_Sprite_En =         $20                 ; Enable the Sprite Module in Vicky
Mstr_Ctrl_GAMMA_En =         $40                 ; this Enable the GAMMA correction - The Analog and DVI have different color value, the GAMMA is great to correct the difference
Mstr_Ctrl_Disable_Vid =         $80                 ; This will disable the Scanning of the Video hence giving 100% bandwith to the CPU
MASTER_CTRL_REG_H =         $D001
; Reserved - TBD
VKY_RESERVED_00 =         $D002
VKY_RESERVED_01 =         $D003
; 
BORDER_CTRL_REG =         $D004               ; Bit[0] - Enable (1 by default)  Bit[4..6]: X Scroll Offset ( Will scroll Left) (Acceptable Value: 0..7)
Border_Ctrl_Enable =         $01
BORDER_COLOR_B =         $D005
BORDER_COLOR_G =         $D006
BORDER_COLOR_R =         $D007
BORDER_X_SIZE  =         $D008               X-  Values: 0 - 32 (Default: 32)
BORDER_Y_SIZE  =         $D009               Y- Values 0 -32 (Default: 32)
; Reserved - TBD

VKY_TXT_CURSOR_CTRL_REG =         $D010               ;[0]  Enable Text Mode

TEXT_LUT_FG    =         $D800
TEXT_LUT_BG    =         $D840

init_display             

               clr       io_ctrl

               lda       #Mstr_Ctrl_Text_Mode_En
               ora       #Mstr_Ctrl_GAMMA_En
               sta       MASTER_CTRL_REG_L
               clr       MASTER_CTRL_REG_H

               clr       BORDER_CTRL_REG
               clr       BORDER_COLOR_R
               clr       BORDER_COLOR_G
               clr       BORDER_COLOR_B

               clr       VKY_TXT_CURSOR_CTRL_REG

               jsr       install_palette

               jsr       install_font
               ldb       #3
               stb       io_ctrl
               lda       #$10
               jsr       fill
               jmp       cls

cls                      
               ldb       #2                  ; text
               stb       io_ctrl
               lda       #$20
               jsr       fill
               ldx       #0
               clr       io_ctrl
               rts       

fill                     
               tfr       a,b
               ldx       #$c000
4$             ;std                          ,x++
               sta       ,x+
               stb       ,x+
               cmpx      #$c000+80*61
               bne       4$
               rts       

putstr                   
               lda       ,x+
               beq       putstrdone
               bsr       putch
               bra       putstr
putstrdone     rts       

putch          pshs      d,x
               ldx       next_char
               ldb       #2
               stb       io_ctrl
               sta       ,x+
               cmpx      #80*60
               bne       x1@
               jsr       scroll
x1@            stx       next_char
               clr       io_ctrl
               puls      d,x,pc

scroll                   
               ldx       #$c000
x1@            ldd       80,x
               sta       ,x+
               stb       ,x+
               cmpx      #$c000+80*60
               bne       x1@
               leax      -80,x
               rts       

install_font             
               lda       #1
               sta       io_ctrl
               ldx       #0
x@             ldd       font,x
               std       $c000,x
               leax      2,x
               cmpx      #2048
               bne       x@
               clr       io_ctrl
               rts       

install_palette           
               clr       io_ctrl
               jsr       init_gamma

               ldx       #0
x@                       
               lda       y2+0,x
               sta       TEXT_LUT_FG+3,x
               sta       TEXT_LUT_BG+3,x
               lda       y2+1,x
               sta       TEXT_LUT_FG+2,x
               sta       TEXT_LUT_BG+2,x
               lda       y2+2,x
               sta       TEXT_LUT_FG+1,x
               sta       TEXT_LUT_BG+1,x
               lda       y2+3,x
               sta       TEXT_LUT_FG+0,x
               sta       TEXT_LUT_BG+0,x
               leax      4,x
               cmpx      #64
               bne       x@
               rts       
y2                       
               fcb       $00,$00,$00,$00
               fcb       $00,$ff,$ff,$ff
               fcb       $00,$88,$00,$00
               fcb       $00,$aa,$ff,$ee
               fcb       $00,$cc,$44,$cc
               fcb       $00,$00,$cc,$55
               fcb       $00,$00,$00,$aa
               fcb       $00,$dd,$dd,$77
               fcb       $00,$dd,$88,$55
               fcb       $00,$66,$44,$00
               fcb       $00,$ff,$77,$77
               fcb       $00,$33,$33,$33
               fcb       $00,$77,$77,$77
               fcb       $00,$aa,$ff,$66
               fcb       $00,$00,$88,$ff
               fcb       $00,$bb,$bb,$bb

init_gamma               
               clr       io_ctrl
               ldd       #0
x1@            tfr       d,x
               stb       $c000,x
               stb       $c400,x
               stb       $c800,x
               incb      
               bne       x1@
               rts       

font                     
               use       "8x8.fcb"

               rmb       $FFF0-*

               org       vectors
               fdb       0
               fdb       swi3
               fdb       swi2
               fdb       firq
               fdb       irq
               fdb       swi
               fdb       nmi
               fdb       reset

               end       main

