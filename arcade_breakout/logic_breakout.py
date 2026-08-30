import tkinter as tk
import random

WIDTH, HEIGHT = 800, 600
PADDLE_W, PADDLE_H = 110, 16
BALL_R = 8
ROWS, COLS = 6, 10
BRICK_GAP = 5
BRICK_H = 24
TOP = 70
SIDE = 35

class Breakout:
    def __init__(self, root):
        self.root = root
        self.root.title("Logic Breakout")
        self.canvas = tk.Canvas(root, width=WIDTH, height=HEIGHT, bg="#10131a",
                                highlightthickness=0)
        self.canvas.pack()
        self.keys = set()
        self.score = 0
        self.lives = 3
        self.running = True

        self.canvas.create_text(18, 20, anchor="w", fill="white",
                                font=("Courier", 16, "bold"),
                                text="LOGIC BREAKOUT")
        self.info = self.canvas.create_text(
            WIDTH - 18, 20, anchor="e", fill="white",
            font=("Courier", 13), text=""
        )

        self.paddle = self.canvas.create_rectangle(
            WIDTH//2-PADDLE_W//2, HEIGHT-45,
            WIDTH//2+PADDLE_W//2, HEIGHT-45+PADDLE_H,
            fill="#f4f4f4", outline=""
        )

        self.bricks = []
        colors = ["#ff595e", "#ff924c", "#ffca3a",
                  "#8ac926", "#1982c4", "#6a4c93"]
        usable = WIDTH - 2*SIDE
        brick_w = (usable - (COLS-1)*BRICK_GAP) / COLS

        for row in range(ROWS):
            for col in range(COLS):
                x1 = SIDE + col*(brick_w + BRICK_GAP)
                y1 = TOP + row*(BRICK_H + BRICK_GAP)
                b = self.canvas.create_rectangle(
                    x1, y1, x1+brick_w, y1+BRICK_H,
                    fill=colors[row], outline="#10131a", width=2
                )
                self.bricks.append(b)

        self.ball = self.canvas.create_oval(0, 0, 0, 0,
                                            fill="white", outline="")
        self.reset_ball()

        root.bind("<KeyPress>", self.key_down)
        root.bind("<KeyRelease>", self.key_up)
        root.bind("<space>", self.restart)

        self.update_info()
        self.loop()

    def reset_ball(self):
        x, y = WIDTH/2, HEIGHT-80
        self.canvas.coords(self.ball, x-BALL_R, y-BALL_R,
                           x+BALL_R, y+BALL_R)
        self.vx = random.choice([-4.2, 4.2])
        self.vy = -4.2

    def key_down(self, e):
        self.keys.add(e.keysym)

    def key_up(self, e):
        self.keys.discard(e.keysym)

    def update_info(self):
        self.canvas.itemconfig(
            self.info, text=f"SCORE {self.score:03d}   LIVES {self.lives}"
        )

    def restart(self, event=None):
        if not self.running:
            self.root.destroy()
            main()

    def end_message(self, text):
        self.running = False
        self.canvas.create_rectangle(
            180, 245, 620, 355, fill="#10131a", outline="white", width=2
        )
        self.canvas.create_text(
            WIDTH/2, 285, fill="white", font=("Courier", 24, "bold"), text=text
        )
        self.canvas.create_text(
            WIDTH/2, 325, fill="white", font=("Courier", 12),
            text="Premi SPAZIO per ricominciare"
        )

    def loop(self):
        if self.running:
            # Paddle: frecce sinistra/destra
            px1, py1, px2, py2 = self.canvas.coords(self.paddle)
            dx = 0
            if "Left" in self.keys:
                dx -= 7
            if "Right" in self.keys:
                dx += 7
            if px1 + dx < 0:
                dx = -px1
            if px2 + dx > WIDTH:
                dx = WIDTH - px2
            self.canvas.move(self.paddle, dx, 0)

            # Ball
            self.canvas.move(self.ball, self.vx, self.vy)
            x1, y1, x2, y2 = self.canvas.coords(self.ball)

            if x1 <= 0 and self.vx < 0:
                self.vx *= -1
            if x2 >= WIDTH and self.vx > 0:
                self.vx *= -1
            if y1 <= 42 and self.vy < 0:
                self.vy *= -1

            # Paddle collision
            p = self.canvas.coords(self.paddle)
            if (self.vy > 0 and y2 >= p[1] and y1 <= p[3]
                    and x2 >= p[0] and x1 <= p[2]):
                center_ball = (x1+x2)/2
                center_pad = (p[0]+p[2])/2
                relative = (center_ball-center_pad)/(PADDLE_W/2)
                self.vx = relative * 6
                self.vy = -abs(self.vy)

            # Brick collision
            hits = self.canvas.find_overlapping(x1, y1, x2, y2)
            for obj in hits:
                if obj in self.bricks:
                    self.canvas.delete(obj)
                    self.bricks.remove(obj)
                    self.vy *= -1
                    self.score += 10
                    self.update_info()
                    break

            if not self.bricks:
                self.end_message("HAI VINTO!")

            # Miss
            if y1 > HEIGHT:
                self.lives -= 1
                self.update_info()
                if self.lives <= 0:
                    self.end_message("GAME OVER")
                else:
                    self.reset_ball()

        self.root.after(16, self.loop)

def main():
    root = tk.Tk()
    Breakout(root)
    root.resizable(False, False)
    root.mainloop()

if __name__ == "__main__":
    main()
