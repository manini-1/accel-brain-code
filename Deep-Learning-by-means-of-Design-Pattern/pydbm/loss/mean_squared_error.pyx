# -*- coding: utf-8 -*-
import numpy as np
cimport numpy as np
from pydbm.loss.interface.computable_loss import ComputableLoss


class MeanSquaredError(ComputableLoss):
    '''
    The mean squared error (MSE).

    References:
        - Pascanu, R., Mikolov, T., & Bengio, Y. (2012). Understanding the exploding gradient problem. CoRR, abs/1211.5063, 2.
        - Pascanu, R., Mikolov, T., & Bengio, Y. (2013, February). On the difficulty of training recurrent neural networks. In International conference on machine learning (pp. 1310-1318).
    '''

    def __init__(self, grad_clip_threshold=1e+05):
        '''
        Init.

        Args:
            grad_clip_threshold:    Threshold of the gradient clipping.
        '''
        self.penalty_arr = None
        self.__grad_clip_threshold = grad_clip_threshold

    def compute_loss(self, np.ndarray pred_arr, np.ndarray labeled_arr, axis=None):
        '''
        Return of result from this Cost function.

        Args:
            pred_arr:       Predicted data.
            labeled_arr:    Labeled data.
            axis:           Axis or axes along which the losses are computed.
                            The default is to compute the losses of the flattened array.

        Returns:
            Cost.
        '''
        cdef int batch_size = labeled_arr.shape[0]
        cdef np.ndarray diff_arr = (labeled_arr - pred_arr) / batch_size
        v = np.linalg.norm(diff_arr)
        if v > self.__grad_clip_threshold:
            diff_arr = diff_arr * self.__grad_clip_threshold / v

        if self.penalty_arr is not None:
            diff_arr += self.penalty_arr

        return np.square(diff_arr).mean(axis=axis)

    def compute_delta(self, np.ndarray pred_arr, np.ndarray labeled_arr, delta_output=1):
        '''
        Backward delta.
        
        Args:
            pred_arr:       Predicted data.
            labeled_arr:    Labeled data.
            delta_output:   Delta.

        Returns:
            Delta.
        '''
        cdef int batch_size = labeled_arr.shape[0]
        cdef np.ndarray delta_arr = (pred_arr - labeled_arr) / batch_size * delta_output
        v = np.linalg.norm(delta_arr)
        if v > self.__grad_clip_threshold:
            delta_arr = delta_arr * self.__grad_clip_threshold / v

        if self.penalty_arr is not None:
            delta_arr += self.penalty_arr

        return delta_arr

    def reverse_delta(self, np.ndarray delta_arr, np.ndarray labeled_arr, delta_output=1):
        '''
        Reverse delta.

        Args:
            delta_arr:      Gradients data.
            labeled_arr:    Labeled data.
            delta_output:   Delta.

        Returns:
            Delta.
        '''
        cdef int batch_size = labeled_arr.shape[0]
        delta_arr = delta_arr * (batch_size * delta_output) + labeled_arr
        return delta_arr
