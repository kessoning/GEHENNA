PShader shader, blur;

PGraphics pg1, pg2, pg3;

float frCount = 0.0;

void settings() {
  size(1920, 1080, P3D);
}

void setup() {
  
  int w_ = width/2;
  int h_ = height/2;
  pg1 = createGraphics(w_, h_, P3D);
  pg2 = createGraphics(w_, h_, P3D);
  pg3 = createGraphics(w_, h_, P3D);

  frameRate(1000);

  shader = loadShader("shader.glsl");
  shader.set("resolution", float(pg1.width), float(pg1.height));
  shader.set("time", 0.0);
  shader.set("volume", 0.0);

  blur = loadShader("blur.glsl");
  blur.set("iResolution", float(pg1.width), float(pg1.height));

  frCount = 64.5007;
}

void draw() {
  shader.set("time", frCount);
  shader.set("depth", false);
  pg1.beginDraw();
  pg1.shader(shader);
  pg1.rect(0, 0, pg1.width, pg1.height);
  pg1.endDraw();

  shader.set("depth", true);
  pg2.beginDraw();
  pg2.shader(shader);
  pg2.rect(0, 0, pg2.width, pg2.height);
  pg2.endDraw();

  blur.set("imageInput", pg1);
  blur.set("depthMask", pg2);
  blur.set("iTime", frCount);
  pg3.beginDraw();
  pg3.shader(blur);
  pg3.rect(0, 0, pg3.width, pg3.height);
  pg3.endDraw();

  image(pg3, 0, 0, width, height);

  frCount += 1 / frameRate;
}
