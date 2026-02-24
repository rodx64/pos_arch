"""
Módulo de calculadora simples.

Este módulo demonstra funções básicas que serão
testadas pelo nosso seletor de testes com IA.
"""


def somar(a: int, b: int) -> int:
    """Soma dois números."""
    return a + b


def subtrair(a: int, b: int) -> int:
    """Subtrai b de a."""
    return a - b


def multiplicar(a: int, b: int) -> int:
    """Multiplica dois números."""
    return a * b


def dividir(a: int, b: int) -> float:
    """
    Divide a por b.
    
    Raises:
        ValueError: Se b for zero.
    """
    if b == 0:
        raise ValueError("Divisão por zero!")
    return a / b
# Nova feature - FIAP v1
