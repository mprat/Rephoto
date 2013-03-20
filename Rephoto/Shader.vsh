attribute vec4 position;

void main(){
//    gl_Position = vec4(0.0, 0.0, 0.0, 0.0);
    gl_PointSize = 10.0;
    gl_Position = position;
}