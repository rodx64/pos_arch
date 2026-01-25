<?php
$user_id = isset($_GET['id']) ? htmlspecialchars($_GET['id']) : 'Desconhecido';
$timestamp = date('Y-m-d H:i:s');
?>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Página do Usuário</title>
    <style>
        body { font-family: Arial, sans-serif; background-color: #f7e6ff; text-align: center; padding-top: 50px; }
        h1 { color: #6a0dad; }
        p { color: #333; }
        .timestamp { font-size: 0.9em; color: #666; margin-top: 20px; }
    </style>
</head>
<body>
    <h1>Página do Usuário</h1>
    <p>Bem-vindo, usuário ID: <strong><?php echo $user_id; ?></strong></p>
    <p>Esta página foi gerada dinamicamente pelo Apache.</p>
    <p class="timestamp">Gerado em: <?php echo $timestamp; ?></p>
    <p><a href="/">Voltar para Home</a></p>
</body>
</html>