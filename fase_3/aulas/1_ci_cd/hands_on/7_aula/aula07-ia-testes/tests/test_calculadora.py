"""
Testes para o módulo calculadora.

Estes testes só devem rodar quando src/calculadora.py for modificado.
"""
import pytest
from src.calculadora import somar, subtrair, multiplicar, dividir


def test_somar():
    """Testa função de soma."""
    assert somar(2, 3) == 5
    assert somar(-1, 1) == 0
    assert somar(0, 0) == 0


def test_subtrair():
    """Testa função de subtração."""
    assert subtrair(5, 3) == 2
    assert subtrair(3, 5) == -2


def test_multiplicar():
    """Testa função de multiplicação."""
    assert multiplicar(4, 3) == 12
    assert multiplicar(0, 100) == 0


def test_dividir():
    """Testa função de divisão."""
    assert dividir(10, 2) == 5
    assert dividir(7, 2) == 3.5


def test_dividir_por_zero():
    """Testa que divisão por zero levanta erro."""
    with pytest.raises(ValueError):
        dividir(10, 0)
