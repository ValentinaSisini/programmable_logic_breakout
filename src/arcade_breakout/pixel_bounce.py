import pygame
import sys

# ============================================================
# PIXEL BOUNCE
# Simulazione volutamente "a pixel":
# - risoluzione logica 320x240
# - finestra 640x480 (ingrandimento x2 con nearest-neighbour)
# - nessun antialiasing
# - tutte le coordinate e le velocità sono intere
# ============================================================

pygame.init()

# Risoluzione logica: tutto viene disegnato qui.
LOGICAL_W = 320
LOGICAL_H = 240

# La finestra reale è il doppio: ogni pixel logico diventa un blocco 2x2.
SCALE = 2
WINDOW_W = LOGICAL_W * SCALE
WINDOW_H = LOGICAL_H * SCALE

screen = pygame.display.set_mode((WINDOW_W, WINDOW_H))
pygame.display.set_caption("Pixel Bounce")
canvas = pygame.Surface((LOGICAL_W, LOGICAL_H))
clock = pygame.time.Clock()

FPS = 60

# ------------------------------------------------------------
# Colori
# ------------------------------------------------------------
BACKGROUND = (238, 235, 221)   # fondo chiaro, simile alla carta del disegno
BORDER = (32, 32, 32)
PADDLE_GREEN = (62, 150, 55)
BALL_RED = (210, 30, 25)

# ------------------------------------------------------------
# Campo di gioco
# ------------------------------------------------------------
FIELD_LEFT = 20
FIELD_TOP = 15
FIELD_RIGHT = 300
FIELD_BOTTOM = 225
BORDER_THICKNESS = 3

# Bordo interno effettivo, contro cui rimbalza il quadrato.
INNER_LEFT = FIELD_LEFT + BORDER_THICKNESS
INNER_TOP = FIELD_TOP + BORDER_THICKNESS
INNER_RIGHT = FIELD_RIGHT - BORDER_THICKNESS
INNER_BOTTOM = FIELD_BOTTOM - BORDER_THICKNESS

# ------------------------------------------------------------
# Rettangolo verde
# Posizione e proporzioni riprese dallo schema:
# basso, leggermente a sinistra del centro.
# ------------------------------------------------------------
PADDLE_X = 105
PADDLE_Y = 210
PADDLE_W = 70
PADDLE_H = 10
paddle = pygame.Rect(PADDLE_X, PADDLE_Y, PADDLE_W, PADDLE_H)

# ------------------------------------------------------------
# Quadrato rosso
# Parte sopra e a destra del paddle, scende verso sinistra.
# La sequenza è:
#   1. colpisce il rettangolo verde
#   2. viene mandato verso destra
#   3. colpisce il muro destro
#   4. va verso sinistra e in alto
#   5. colpisce il soffitto
# ------------------------------------------------------------
BALL_SIZE = 12

START_X = 165
START_Y = 145
START_VX = -2
START_VY = 2

ball = pygame.Rect(START_X, START_Y, BALL_SIZE, BALL_SIZE)
vx = START_VX
vy = START_VY


def reset():
    global ball, vx, vy
    ball = pygame.Rect(START_X, START_Y, BALL_SIZE, BALL_SIZE)
    vx = START_VX
    vy = START_VY


def update_ball():
    global vx, vy

    # Movimento interamente a coordinate intere.
    old_ball = ball.copy()
    ball.x += vx
    ball.y += vy

    # --------------------------------------------------------
    # Collisione con il paddle: solo se il quadrato sta scendendo
    # e arriva dall'alto.
    #
    # Qui il paddle "rimanda" intenzionalmente il quadrato verso
    # DESTRA, così da riprodurre esattamente la traiettoria
    # richiesta dal disegno.
    # --------------------------------------------------------
    if vy > 0:
        crossed_paddle_top = (
            old_ball.bottom <= paddle.top and ball.bottom >= paddle.top
        )
        horizontal_overlap = (
            ball.right > paddle.left and ball.left < paddle.right
        )

        if crossed_paddle_top and horizontal_overlap:
            ball.bottom = paddle.top
            vx = 3
            vy = -2

    # --------------------------------------------------------
    # Muro destro
    # --------------------------------------------------------
    if ball.right >= INNER_RIGHT and vx > 0:
        ball.right = INNER_RIGHT
        vx = -vx

    # --------------------------------------------------------
    # Soffitto
    # --------------------------------------------------------
    if ball.top <= INNER_TOP and vy < 0:
        ball.top = INNER_TOP
        vy = -vy

    # Gli altri due bordi servono solo a tenere la simulazione
    # dentro il campo se la si lascia andare a lungo.
    if ball.left <= INNER_LEFT and vx < 0:
        ball.left = INNER_LEFT
        vx = -vx

    if ball.bottom >= INNER_BOTTOM and vy > 0:
        ball.bottom = INNER_BOTTOM
        vy = -vy


def draw():
    canvas.fill(BACKGROUND)

    # Bordo del campo: quattro rettangoli pieni, tutti a pixel.
    pygame.draw.rect(
        canvas,
        BORDER,
        (FIELD_LEFT, FIELD_TOP,
         FIELD_RIGHT - FIELD_LEFT, BORDER_THICKNESS)
    )
    pygame.draw.rect(
        canvas,
        BORDER,
        (FIELD_LEFT, FIELD_BOTTOM - BORDER_THICKNESS,
         FIELD_RIGHT - FIELD_LEFT, BORDER_THICKNESS)
    )
    pygame.draw.rect(
        canvas,
        BORDER,
        (FIELD_LEFT, FIELD_TOP,
         BORDER_THICKNESS, FIELD_BOTTOM - FIELD_TOP)
    )
    pygame.draw.rect(
        canvas,
        BORDER,
        (FIELD_RIGHT - BORDER_THICKNESS, FIELD_TOP,
         BORDER_THICKNESS, FIELD_BOTTOM - FIELD_TOP)
    )

    # Paddle e quadrato.
    pygame.draw.rect(canvas, PADDLE_GREEN, paddle)
    pygame.draw.rect(canvas, BALL_RED, ball)

    # Ingrandimento nearest-neighbour: mantiene l'aspetto pixel-art.
    scaled = pygame.transform.scale(canvas, (WINDOW_W, WINDOW_H))
    screen.blit(scaled, (0, 0))
    pygame.display.flip()


running = True

while running:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_ESCAPE:
                running = False
            elif event.key == pygame.K_r:
                reset()

    update_ball()
    draw()
    clock.tick(FPS)

pygame.quit()
sys.exit()
