/*
VFP math library for the iPhone / iPod touch

Copyright (c) 2007-2008 Wolfgang Engel and Matthias Grundmann
http://code.google.com/p/vfpmathlibrary/

This software is provided 'as-is', without any express or implied warranty.
In no event will the authors be held liable for any damages arising
from the use of this software.
Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it freely,
subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must
not claim that you wrote the original software. If you use this
software in a product, an acknowledgment in the product documentation
would be appreciated but is not required.

2. Altered source versions must be plainly marked as such, and must
not be misrepresented as being the original software.

3. This notice may not be removed or altered from any source distribution.
*/

#ifndef MATRIX_IMPL_H__
#define MATRIX_IMPL_H__

// Multiplies two 4x4 matrices saved in row-major format.
void Matrix4Mul(const float* src_mat_1, const float* src_mat_2, float* dst_ptr);

// Multiplies a 4x4 matrix with a 4-dim. vector.
void Matrix4Vector4Mul(const float* src_mat, const float* src_vec, float* dst_vec);

// Multiplies a 4x4 matrix with a 3-dim. vector. Last coordinate is assumed to be 1.
void Matrix4Vector3Mul(const float* src_mat, const float* src_vec, float* dst_vec);
  
// Multiplies a 4x4 matrix with a 3-dim. vector. Last coordinate is assumed to be w.
void Matrix4Vector3Mul(const float* src_mat, const float* src_vec, float w, float* dst_vec);
  
// Multiplies a 4x4 matrix with a 3-dim. vector. Last coordinate is assumed to be 1. 
void Matrix4Vector3ArrayMul(int num,                          // Number of Vertices.
                            const float* src_mat,             // Source matrix.
                            int src_stride,                   // Source vector stride.
                            const float* src_vec_array,       // Source vector array.
                            int dst_stride,                    // Dest. vector stride.
                            float* dest_vec_array);           // Dest. vector array.
  
  
// Multiplies a 4x4 matrix with a 3-dim. vector. Last coordinate is assumed to be w. 
void Matrix4Vector3ArrayMul(int num,                          // Number of Vertices.
                            const float* src_mat,             // Source matrix.
                            float w,                          // Last coordinate of vectors.
                            int src_stride,                   // Source vector stride.
                            const float* src_vec_array,       // Source vector array.
                            int dst_stride,                    // Dest. vector stride.
                            float* dest_vec_array);           // Dest. vector array.

#endif // MATRIX_IMPL_H__
