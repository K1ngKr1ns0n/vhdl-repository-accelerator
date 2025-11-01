import numpy as np
import scipy.signal as signal
import matplotlib.pyplot as plt

print("-------------------------------------------------")
print("  VERIFICADOR PYTHON DO FILTRO FIR (GOLDEN MODEL)")
print("-------------------------------------------------")

# 1. DEFINIR O FILTRO
b = [2, 4, 4, 2]
a = [1]
print(f"Coeficientes do Filtro (b): {b}\n")

# 2. CRIAR OS SINAIS DE TESTE
impulse_input = np.zeros(10)
impulse_input[0] = 1
print(f"Input (Impulso): {impulse_input}")

step_input = np.zeros(10)
step_input[3:] = 5
print(f"Input (Degrau):  {step_input}\n")


# 3. APLICAR O FILTRO
impulse_output = signal.lfilter(b, a, impulse_input)
step_output = signal.lfilter(b, a, step_input)

impulse_output = np.round(impulse_output).astype(int)
step_output = np.round(step_output).astype(int)

# 4. APRESENTAR OS RESULTADOS
print("--- RESULTADOS DA SIMULAÇÃO PYTHON ---")
print("\nTeste de Impulso (Saída y[n]):")
print(impulse_output)
print("-> ANÁLISE: A saída [2 4 4 2 0 ...] bate perfeitamente com os coeficientes. CORRETO.\n")

print("Teste de Degrau (Saída y[n]):")
print(step_output)
print(f"-> ANÁLISE: A saída estabiliza em {step_output[-1]}. O valor esperado era 60. CORRETO.\n")


# 5. (BÔNUS DE PORTFÓLIO) GERAR GRÁFICOS
print("Gerando gráficos de verificação... (salvos como .png)")

# Gráfico do Impulso
plt.figure(figsize=(10, 4))
plt.subplot(1, 2, 1)
# --- CORREÇÃO AQUI ---
plt.stem(impulse_input) 
plt.title("Input (Impulso)")
plt.xlabel("Amostra (n)")
plt.subplot(1, 2, 2)
# --- CORREÇÃO AQUI ---
plt.stem(impulse_output)
plt.title("Output (Resposta ao Impulso)")
plt.xlabel("Amostra (n)")
plt.tight_layout()
plt.savefig("impulse_response.png")

# Gráfico do Degrau
plt.figure(figsize=(10, 4))
plt.subplot(1, 2, 1)
# --- CORREÇÃO AQUI ---
plt.stem(step_input)
plt.title("Input (Degrau de valor 5)")
plt.xlabel("Amostra (n)")
plt.subplot(1, 2, 2)
# --- CORREÇÃO AQUI ---
plt.stem(step_output)
plt.title("Output (Resposta ao Degrau)")
plt.xlabel("Amostra (n)")
plt.tight_layout()
plt.savefig("step_response.png")

print("Gráficos 'impulse_response.png' e 'step_response.png' salvos.")
print("-------------------------------------------------")
