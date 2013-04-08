#include "Matrix4x4.h"

Matrix4x4::Matrix4x4(){
    Identity();
}

Matrix4x4::Matrix4x4(float e00, float e01, float e02, float e03,
          float e10, float e11, float e12, float e13,
          float e20, float e21, float e22, float e23,
                     float e30, float e31, float e32, float e33){
    values[0] = e00;
    values[1] = e01;
    values[2] = e02;
    values[3] = e03;
    values[4] = e10;
    values[5] = e11;
    values[6] = e12;
    values[7] = e13;
    values[8] = e20;
    values[9] = e21;
    values[10] = e22;
    values[11] = e23;
    values[12] = e30;
    values[13] = e31;
    values[14] = e32;
    values[15] = e33;
}

// Matrix4x4::Matrix4x4(float entries[16]){
//     &values = &entries;
// }

Matrix4x4::Matrix4x4(const float * newentries){
    memcpy(values, newentries, 16*sizeof(float));
}

void Matrix4x4::Identity(void){
    memset(values, 0, 16*sizeof(float));
	values[0]=1.0f;
	values[5]=1.0f;
	values[10]=1.0f;
	values[15]=1.0f;
}

void Matrix4x4::Zero(void){
    memset(values, 0, 16*sizeof(float));
}

//operators
Matrix4x4 Matrix4x4::operator+(const Matrix4x4 &m) const{
    return Matrix4x4(values[0] + m.values[0], values[1] + m.values[1], values[2] + m.values[2], values[3] + m.values[3],
                     values[4] + m.values[4], values[5] + m.values[5], values[6] + m.values[6], values[7] + m.values[7],
                     values[8] + m.values[8], values[9] + m.values[9], values[10] + m.values[10], values[11] + m.values[11],
                     values[12] + m.values[12], values[13] + m.values[13], values[14] + m.values[14], values[15] + m.values[15]);
}

Matrix4x4 Matrix4x4::operator-(const Matrix4x4 &m) const{
    return Matrix4x4(values[0] - m.values[0], values[1] - m.values[1], values[2] - m.values[2], values[3] - m.values[3],
                     values[4] - m.values[4], values[5] - m.values[5], values[6] - m.values[6], values[7] - m.values[7],
                     values[8] - m.values[8], values[9] - m.values[9], values[10] - m.values[10], values[11] - m.values[11],
                     values[12] - m.values[12], values[13] - m.values[13], values[14] - m.values[14], values[15] - m.values[15]);
}

Matrix4x4 Matrix4x4::operator*(const Matrix4x4 &m) const{
    return Matrix4x4(m.values[0]*values[0]+m.values[4]*values[1]+m.values[8]*values[2]+m.values[12]*values[3],
                     m.values[1]*values[0]+m.values[5]*values[1]+m.values[9]*values[2]+m.values[13]*values[3],
                     m.values[2]*values[0]+m.values[6]*values[1]+m.values[10]*values[2]+m.values[14]*values[3],
                     m.values[3]*values[0]+m.values[7]*values[1]+m.values[11]*values[2]+m.values[15]*values[3],
                     m.values[0]*values[4]+m.values[4]*values[5]+m.values[8]*values[6]+m.values[12]*values[7],
                     m.values[1]*values[4]+m.values[5]*values[5]+m.values[9]*values[6]+m.values[13]*values[7],
                     m.values[2]*values[4]+m.values[6]*values[5]+m.values[10]*values[6]+m.values[14]*values[7],
                     m.values[3]*values[4]+m.values[7]*values[5]+m.values[11]*values[6]+m.values[15]*values[7],
                     m.values[0]*values[8]+m.values[4]*values[9]+m.values[8]*values[10]+m.values[12]*values[11],
                     m.values[1]*values[8]+m.values[5]*values[9]+m.values[9]*values[10]+m.values[13]*values[11],
                     m.values[2]*values[8]+m.values[6]*values[9]+m.values[10]*values[10]+m.values[14]*values[11],
                     m.values[3]*values[8]+m.values[7]*values[9]+m.values[11]*values[10]+m.values[15]*values[11],
                     m.values[0]*values[12]+m.values[4]*values[13]+m.values[8]*values[14]+m.values[12]*values[15],
                     m.values[1]*values[12]+m.values[5]*values[13]+m.values[9]*values[14]+m.values[13]*values[15],
                     m.values[2]*values[12]+m.values[6]*values[13]+m.values[10]*values[14]+m.values[14]*values[15],
                     m.values[3]*values[12]+m.values[7]*values[13]+m.values[11]*values[14]+m.values[15]*values[15]);
}

void Matrix4x4::print(){
    std::cout<<values[0]<<" "<<values[1]<<" "<<values[2]<<" "<<values[3]<<std::endl;
    std::cout<<values[4]<<" "<<values[5]<<" "<<values[6]<<" "<<values[7]<<std::endl;
    std::cout<<values[8]<<" "<<values[9]<<" "<<values[10]<<" "<<values[11]<<std::endl;
    std::cout<<values[12]<<" "<<values[13]<<" "<<values[14]<<" "<<values[15]<<std::endl<<std::endl;
}
