attribute vec4 position;
uniform mat4 modelViewProjectionMatrix;

void main(){
    gl_PointSize = 16.0;
//    gl_Position = position;
    gl_Position = modelViewProjectionMatrix*position;
}