import de.bezier.data.sql.mapper.*;
import de.bezier.data.sql.*;

import controlP5.*;

import java.util.concurrent.TimeUnit;

ControlP5 cp;
MySQL mysql;
PFont headerFont;
PFont subHeaderFont;
int state, numResults;
String victorName;
Textarea instrL;
Textlabel userL, passL, hostL, portL, tableL;
Textfield user, pass, host, port;
RadioButton tableR;
Button decideB;
StringList resultsList;

int viewport_w = 1200;
int viewport_h = 900;
int viewport_x = 230;
int viewport_y = 0;

//----------Fluid text stuff
int fluidgrid_scale = 1;

DwPixelFlow context;
DwFluid2D fluid;
MyFluidData cb_fluid_data;
DwFluidParticleSystem2D particle_system;


PGraphics2D pg_fluid;       // render target
PGraphics2D pg_obstacles;   // texture-buffer, for adding obstacles
PGraphics2D pg_text;        // texture-buffer, for adding fluid data (density and temperature)

// sprite, can be used for the particle system
PImage img_sprite;

// processing font
PFont font;

boolean UPDATE_FLUID = true;

void setup() {
  size(1200, 900, P2D);
  smooth(4);
  background(0);
  
  cp = new ControlP5(this);
  headerFont = createFont("BookmanOldStyle", 32, true);
  subHeaderFont = createFont("BookmanOldStyle", 24, true);
  font = createFont("BookmanOldStyle", 48);
  resultsList = new StringList();
  
  state = 0;
  numResults = 0;
  
  showLoginScreen();
  
  
  
  //----------Fluid text stuff
  surface.setLocation(viewport_x, viewport_y);
  
  // main library context
  context = new DwPixelFlow(this);
  // fluid simulation
  fluid = new DwFluid2D(context, viewport_w, viewport_h, fluidgrid_scale);
  
  // fuild simulation parameters
  fluid.param.dissipation_density     = 0.75f;
  fluid.param.dissipation_velocity    = 0.90f;
  fluid.param.dissipation_temperature = 0.90f;
  
  // interface for adding data to the fluid simulation
  cb_fluid_data = new MyFluidData();
  fluid.addCallback_FluiData(cb_fluid_data);

  // fluid render target
  pg_fluid = (PGraphics2D) createGraphics(viewport_w, viewport_h, P2D);
  pg_fluid.smooth(4);

  // particles
  particle_system = new DwFluidParticleSystem2D();
  particle_system.resize(context, viewport_w/3, viewport_h/3);
  
  // obstacles buffer
  pg_obstacles = (PGraphics2D) createGraphics(viewport_w, viewport_h, P2D);
  pg_obstacles.noSmooth();
  pg_obstacles.beginDraw();
  pg_obstacles.clear();
  pg_obstacles.endDraw();
  
  // add the obstacles to the simulation
  fluid.addObstacles(pg_obstacles);
 
  // buffer, for fluid data
  pg_text = (PGraphics2D) createGraphics(viewport_w, viewport_h, P2D);

  // sprite for fluid particles
  img_sprite = loadImage("../data/sprite.png");

  frameRate(60);
}

void draw() {
  if (state == 1) {
    showLoginScreen();
  } else if (state == 2) {
    //clean up login screen
    instrL.remove();
    userL.remove();
    passL.remove();
    hostL.remove();
    portL.remove();
    tableL.remove();
    user.remove();
    pass.remove();
    host.remove();
    port.remove();
    tableR.remove();
    decideB.remove();
    
    int victorIndex = int(random(resultsList.size()));
    victorName = resultsList.get(victorIndex);
    drawText(pg_text);
  } else if (state == 3) {
    narrowResults();
  } else if (state == 4) {
    showVictor();
  }
  
  //----------Fluid text stuff
  if(state > 1){
    //drawText(pg_text);
    fluid.addObstacles(pg_obstacles);
    fluid.update();
    particle_system.update(fluid);
    
    pg_fluid.beginDraw();
    pg_fluid.background(0);
    pg_fluid.endDraw();
    
    fluid.renderFluidTextures(pg_fluid, 0);
    image(pg_fluid    , 0, 0);
    image(pg_obstacles, 0, 0);
    image(pg_text     , 0, 0);
  }

}

void showVictor() {
  state = 5;

  println("\nAnd the victor is: ", victorName);
}

void narrowResults() {
  state = 4;
  
  int currLeft = numResults - 1;

  while (currLeft > 0) {
    resultsList.shuffle();
    
    if (resultsList.get(currLeft).equals(victorName)) {
      resultsList.remove(0);
    } else {
      resultsList.remove(currLeft);
    }
    
    currLeft -= 1;
    
    if (currLeft % 5 == 0 && currLeft != 0) {
      println('\n', "Next round. Printing remaining results.", '\n');
      for (String s:resultsList) {
        println(s);
      }
      //try {
      //  Thread.sleep(1000);
      //} catch(InterruptedException ex) {
      //  Thread.currentThread().interrupt();
      //}
      //pg_text.dispose();
    }
  }
}

void decide() {
  mysql = new MySQL(this, host.getText(), "mediatodolist_mike", user.getText(), pass.getText());
  
  if (!mysql.connect()) {
    println("Conection failed!");
    state = 1;
  } else {
    println("Connection succeeded!");
    state = 2;
  }
  
  switch(int(tableR.getValue())) {
    case(1): mysql.query("SELECT * FROM movies WHERE status = 1"); break;
    case(2): mysql.query("SELECT * FROM tv WHERE status = 1"); break;
    case(3): mysql.query("SELECT * FROM books WHERE status = 1 OR status = 2"); break;
    case(4): mysql.query("SELECT * FROM games WHERE status = 1 OR status = 2"); break;
  }
  
  while (mysql.next()) {
    String t = mysql.getString("name");
    resultsList.append(t);
    numResults += 1;
  }
  
  resultsList.shuffle();
}

public void drawText(PGraphics pg){
  state = 3;
  
  surface.setSize(1200, 900);
  
  int currX = 25, currY = 50;
  boolean notFull = true;
  
  pg.beginDraw();
  pg.clear();
 
  pg.textFont(font);
  
  for (int i = 0; i < numResults && notFull; i++) {
    
    pg.fill(255);
    String t = resultsList.get(i);
    
    if ((currX + t.length() * 24) > 1175) {
      currX = 25;
      currY += 50;
    }
    if (currY > 750) {
      notFull = false;
    }
    
    println(currX, currY);
    println(t);
    
    if (t != victorName) {
      pg.text(t, currX, currY);
    }
    else {
      pg.fill(255, 0, 0);
      pg.text(t, currX, currY);
    }
    
    currX += t.length() * 24 + 32;
    
    if (!resultsList.hasValue(t)) {
      resultsList.append(t);
      numResults += 1;
    }
  }
  
  pg.fill(0, 0, 255);
  pg.text("And the victor is: " + victorName, 25, 850);
  pg.endDraw();
}

void showLoginScreen() {
  state = 0;
  
  surface.setSize(400, 500);
  
  instrL = cp.addTextarea("instrL")
             .setText("Please enter database information:")
             .setPosition(20, 20)
             .setSize(350, 100)
             .setFont(headerFont);
    
  userL = cp.addTextlabel("userL")
            .setText("Username:")
            .setPosition(20, 150)
            .setSize(100, 50)
            .setFont(subHeaderFont); 
  
  passL = cp.addTextlabel("passL")
            .setText("Password:")
            .setPosition(20, 200)
            .setSize(100, 50)
            .setFont(subHeaderFont); 
            
  hostL = cp.addTextlabel("hostL")
            .setText("Hostname:")
            .setPosition(20, 250)
            .setSize(100, 50)
            .setFont(subHeaderFont); 
            
  portL = cp.addTextlabel("portL")
            .setText("Port:")
            .setPosition(20, 300)
            .setSize(100, 50)
            .setFont(subHeaderFont); 
            
  tableL = cp.addTextlabel("tableL")
             .setText("Media Type:")
             .setPosition(20, 350)
             .setSize(100, 50)
             .setFont(subHeaderFont); 
    
  user = cp.addTextfield("username")
           .setPosition(175, 145)
           .setCaptionLabel("")
           .setSize(200, 40)
           .setFont(subHeaderFont);
    
  pass = cp.addTextfield("password")
           .setPosition(175, 195)
           .setCaptionLabel("")
           .setSize(200, 40)
           .setPasswordMode(true)
           .setFont(subHeaderFont);
    
  host = cp.addTextfield("host")
           .setPosition(175, 245)
           .setCaptionLabel("")
           .setSize(200, 40)
           .setFont(subHeaderFont);
    
  port = cp.addTextfield("port")
           .setPosition(175, 295)
           .setCaptionLabel("")
           .setSize(200, 40)
           .setFont(subHeaderFont);
        
  tableR = cp.addRadioButton("tableR")
            .setPosition(175, 350)
            .setItemsPerRow(2)
            .setSpacingColumn(65)
            .setSize(50, 20)
            .setFont(subHeaderFont)
            .setNoneSelectedAllowed(false)
            .addItem("movies", 1)
            .addItem("shows", 2)
            .addItem("books", 3)
            .addItem("games", 4);
  
  tableR.activate(0);  
    
  decideB = cp.addButton("decide")
              .setPosition(25, 420)
              .setSize(350, 40)
              .setFont(subHeaderFont);
  
}