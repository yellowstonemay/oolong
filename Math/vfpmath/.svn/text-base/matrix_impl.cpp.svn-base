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

#ifdef __APPLE__
#include <TargetConditionals.h>
#if (TARGET_IPHONE_SIMULATOR == 0) && (TARGET_OS_IPHONE == 1)

#include "matrix_impl.h"
#include "common_macros.h"

void Matrix4Mul(const float* src_mat_1, const float* src_mat_2, float* dst_mat) {
  asm volatile (VFP_SWITCH_TO_ARM
                VFP_VECTOR_LENGTH(3)

                // Interleaving loads and adds/muls for faster calculation.
                // Let A:=src_ptr_1, B:=src_ptr_2, then
                // function computes A*B as (B^T * A^T)^T.
                
                // Load the whole matrix into memory - transposed -> second operand first.
                "fldmias  %2, {s8-s23}    \n\t"
                // Load first column to scalar bank.
                "fldmias  %1!, {s0-s3}    \n\t"
                // First column times matrix.
                "fmuls s24, s8, s0        \n\t"
                "fmacs s24, s12, s1       \n\t"

                // Load second column to scalar bank.
                "fldmias %1!,  {s4-s7}    \n\t"

                "fmacs s24, s16, s2       \n\t"
                "fmacs s24, s20, s3       \n\t"
                // Save first column.
                "fstmias  %0!, {s24-s27}  \n\t" 
  
                 // Second column times matrix.
                "fmuls s28, s8, s4        \n\t"
                "fmacs s28, s12, s5       \n\t"
		
                // Load third column to scalar bank.
                "fldmias  %1!, {s0-s3}    \n\t"

                "fmacs s28, s16, s6       \n\t"
                "fmacs s28, s20, s7       \n\t"
                // Save second column.
                "fstmias  %0!, {s28-s31}  \n\t" 
                
                // Third column times matrix.
                "fmuls s24, s8, s0        \n\t"
                "fmacs s24, s12, s1       \n\t"
		
                // Load fourth column to scalar bank.
                "fldmias %1!,  {s4-s7}    \n\t"

                "fmacs s24, s16, s2       \n\t"
                "fmacs s24, s20, s3       \n\t"
                 // Save third column.
                "fstmias  %0!, {s24-s27}  \n\t" 
                                
                // Fourth column times matrix.
                "fmuls s28, s8, s4        \n\t"
                "fmacs s28, s12, s5       \n\t"
                "fmacs s28, s16, s6       \n\t"
                "fmacs s28, s20, s7       \n\t"
                // Save fourth column.
                "fstmias  %0!, {s28-s31}  \n\t" 
                
                VFP_VECTOR_LENGTH_ZERO
                VFP_SWITCH_TO_THUMB
                : "=r" (dst_mat), "=r" (src_mat_1)
                : "r" (src_mat_2), "0" (dst_mat), "1" (src_mat_1)
                : "r0"
                );
}

void Matrix4Vector4Mul(const float* src_mat, const float* src_vec, float* dst_vec) {
  asm volatile (VFP_SWITCH_TO_ARM
                // Load the matrix transposed into memory.
                // Any idea how to make this faster ?
                // Calculating explictly is not really an option.
                "fldmias  %0!, {s8-s11}    \n\t"
                "fcpys s12, s9             \n\t"
                "fcpys s16, s10            \n\t"
                "fldmias  %0!, {s24-s27}   \n\t"
                "fcpys s20, s11            \n\t"
                "fcpys s9,  s24            \n\t"
                "fcpys s13, s25            \n\t"
                "fldmias  %0!, {s28-s31}   \n\t"
                "fcpys s17, s26            \n\t"
                "fcpys s21, s27            \n\t"
                
                "fcpys s10,  s28           \n\t"
                "fcpys s14, s29            \n\t"
                "fldmias  %0!, {s24-s27}   \n\t"
                "fcpys s18, s30            \n\t"
                "fcpys s22, s31            \n\t"
                
                "fcpys s11, s24            \n\t"
                "fcpys s15, s25            \n\t"
                
                // Load vector to scalar bank.
                "fldmias  %1, {s0-s3}    \n\t"
                
                "fcpys s19, s26            \n\t"
                "fcpys s23, s27            \n\t"
                
                VFP_VECTOR_LENGTH(3)
                
                // First column times matrix.
                "fmuls s24, s8, s0        \n\t"
                "fmacs s24, s12, s1       \n\t"
                "fmacs s24, s16, s2       \n\t"
                "fmacs s24, s20, s3       \n\t"
                
                // Save vector.
                "fstmias  %2, {s24-s27}  \n\t" 
                
                VFP_VECTOR_LENGTH_ZERO
                VFP_SWITCH_TO_THUMB
                : "=r" (src_mat)
                : "r" (src_vec), "r" (dst_vec), "0" (src_mat)
                : "r0"
                );  
}
  
void Matrix4Vector3Mul(const float* src_mat, const float* src_vec, float* dst_vec) {  
  asm volatile (VFP_SWITCH_TO_ARM
                // Load the matrix transposed into memory.
                // Any idea how to make this faster ?
                // Calculating explictly is not really an option.
                "fldmias  %0!, {s8-s11}    \n\t"
                "fcpys s12, s9             \n\t"
                "fcpys s16, s10            \n\t"
                "fldmias  %0!, {s24-s27}   \n\t"
                "fcpys s20, s11            \n\t"
                "fcpys s9,  s24            \n\t"
                "fcpys s13, s25            \n\t"
                "fldmias  %0!, {s28-s31}   \n\t"
                "fcpys s17, s26            \n\t"
                "fcpys s21, s27            \n\t"
                
                "fcpys s10,  s28           \n\t"
                "fcpys s14, s29            \n\t"
                "fldmias  %0!, {s24-s27}   \n\t"
                "fcpys s18, s30            \n\t"
                "fcpys s22, s31            \n\t"
                
                "fcpys s11, s24            \n\t"
                "fcpys s15, s25            \n\t"
                
                // Load vector to scalar bank.
                "fldmias  %1, {s0-s2}    \n\t"
                
                "fcpys s19, s26            \n\t"
                "fcpys s23, s27            \n\t"
                
                VFP_VECTOR_LENGTH(3)
                
                // First column times matrix.
                "fmuls s24, s8, s0        \n\t"
                "fmacs s24, s12, s1       \n\t"
                "fmacs s24, s16, s2       \n\t"
                "fadds s24, s24, s20      \n\t"
                
                // Save vector.
                "fstmias  %2, {s24-s27}  \n\t" 
                
                VFP_VECTOR_LENGTH_ZERO
                VFP_SWITCH_TO_THUMB
                : "=r" (src_mat)
                : "r" (src_vec), "r" (dst_vec), "0" (src_mat)
                : "r0"
                );  
}
  
void Matrix4Vector3Mul(const float* src_mat, const float* src_vec, float w, float* dst_vec) {  
    asm volatile (VFP_SWITCH_TO_ARM
                  // Load the matrix transposed into memory.
                  // Any idea how to make this faster ?
                  // Calculating explictly is not really an option.
                  "fldmias  %0!, {s8-s11}    \n\t"
                  "fcpys s12, s9             \n\t"
                  "fcpys s16, s10            \n\t"
                  "fldmias  %0!, {s24-s27}   \n\t"
                  "fcpys s20, s11            \n\t"
                  "fcpys s9,  s24            \n\t"
                  "fcpys s13, s25            \n\t"
                  "fldmias  %0!, {s28-s31}   \n\t"
                  "fcpys s17, s26            \n\t"
                  "fcpys s21, s27            \n\t"
                  
                  "fcpys s10,  s28           \n\t"
                  "fcpys s14, s29            \n\t"
                  "fldmias  %0!, {s24-s27}   \n\t"
                  "fcpys s18, s30            \n\t"
                  "fcpys s22, s31            \n\t"
                  
                  "fcpys s11, s24            \n\t"
                  "fcpys s15, s25            \n\t"
                  
                  // Load vector to scalar bank.
                  "fldmias  %1, {s0-s2}    \n\t"
                  
                  "fcpys s19, s26            \n\t"
                  "fcpys s23, s27            \n\t"
                  
                  // Load w.
                  "fmsr   s3, %3             \n\t"
                  
                  VFP_VECTOR_LENGTH(3)
                  
                  // First column times matrix.
                  "fmuls s24, s8, s0        \n\t"
                  "fmacs s24, s12, s1       \n\t"
                  "fmacs s24, s16, s2       \n\t"
                  "fmacs s24, s20, s3       \n\t"                  
                  
                  // Save vector.
                  "fstmias  %2, {s24-s27}  \n\t" 
                  
                  VFP_VECTOR_LENGTH_ZERO
                  VFP_SWITCH_TO_THUMB
                  : "=r" (src_mat)
                  : "r" (src_vec), "r" (dst_vec), "r" (w), "0" (src_mat)
                  : "r0"
                  );  
}
  
#endif
#endif
