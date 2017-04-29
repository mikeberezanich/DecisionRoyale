import com.thomasdiewald.pixelflow.java.*;
import com.thomasdiewald.pixelflow.java.accelerationstructures.*;
import com.thomasdiewald.pixelflow.java.antialiasing.FXAA.*;
import com.thomasdiewald.pixelflow.java.antialiasing.GBAA.*;
import com.thomasdiewald.pixelflow.java.antialiasing.SMAA.*;
import com.thomasdiewald.pixelflow.java.dwgl.*;
import com.thomasdiewald.pixelflow.java.fluid.*;
import com.thomasdiewald.pixelflow.java.geometry.*;
import com.thomasdiewald.pixelflow.java.imageprocessing.*;
import com.thomasdiewald.pixelflow.java.imageprocessing.filter.*;
import com.thomasdiewald.pixelflow.java.render.skylight.*;
import com.thomasdiewald.pixelflow.java.rigid_origami.*;
import com.thomasdiewald.pixelflow.java.sampling.*;
import com.thomasdiewald.pixelflow.java.softbodydynamics.*;
import com.thomasdiewald.pixelflow.java.softbodydynamics.constraint.*;
import com.thomasdiewald.pixelflow.java.softbodydynamics.particle.*;
import com.thomasdiewald.pixelflow.java.softbodydynamics.softbody.*;
import com.thomasdiewald.pixelflow.java.utils.*;

private class MyFluidData implements DwFluid2D.FluidData{
    
  @Override
  // this is called during the fluid-simulation update step.
  public void update(DwFluid2D fluid) {
    // use the text as input for density and temperature
    addDensityTexture    (fluid, pg_text);
    addTemperatureTexture(fluid, pg_text);
  }
  
  // custom shader, to add density from a texture (PGraphics2D) to the fluid.
  public void addDensityTexture(DwFluid2D fluid, PGraphics2D pg){
    int[] pg_tex_handle = new int[1];
//      pg_tex_handle[0] = pg.getTexture().glName;
    context.begin();
    context.getGLTextureHandle(pg, pg_tex_handle);
    context.beginDraw(fluid.tex_density.dst);

    DwGLSLProgram shader = context.createShader("data/addDensity.frag");
    shader.begin();
    shader.uniform2f     ("wh"        , fluid.fluid_w, fluid.fluid_h);                                                                   
    shader.uniform1i     ("blend_mode", 6);   
    shader.uniform1f     ("mix_value" , 0.05f);     
    shader.uniform1f     ("multiplier", 1);     
    shader.uniformTexture("tex_ext"   , pg_tex_handle[0]);
    shader.uniformTexture("tex_src"   , fluid.tex_density.src);
    shader.drawFullScreenQuad();
    shader.end();
    context.endDraw();
    context.end("app.addDensityTexture");
    fluid.tex_density.swap();
  }
  
  public void addTemperatureTexture(DwFluid2D fluid, PGraphics2D pg){
    int[] pg_tex_handle = new int[1];
//      pg_tex_handle[0] = pg.getTexture().glName;
    context.begin();
    context.getGLTextureHandle(pg, pg_tex_handle);
    context.beginDraw(fluid.tex_temperature.dst);
    DwGLSLProgram shader = context.createShader("data/addTemperature.frag");
    shader.begin();
    shader.uniform2f     ("wh"        , fluid.fluid_w, fluid.fluid_h);                                                                   
    shader.uniform1i     ("blend_mode", 1);   
    shader.uniform1f     ("mix_value" , 0.02f);     
    shader.uniform1f     ("multiplier", 0.015f);     
    shader.uniformTexture("tex_ext"   , pg_tex_handle[0]);
    shader.uniformTexture("tex_src"   , fluid.tex_temperature.src);
    shader.drawFullScreenQuad();
    shader.end();
    context.endDraw();
    context.end("app.addTemperatureTexture");
    fluid.tex_temperature.swap();
  }

}