# 🔄 INSTRUÇÕES DE RESTAURAÇÃO v2.0

## Para restaurar o sistema no futuro:

### 1. Baixar o código do GitHub
```bash
git clone https://github.com/devdiogofalves/Prospectacontatte.git
cd Prospectacontatte
git checkout v2.0
```

### 2. Restaurar o banco de dados
```bash
# Parar containers
docker compose stop

# Recriar banco
docker compose down -v
docker compose up -d db

# Restaurar dump
psql -U supabase_admin -d postgres < database.sql
```

### 3. Restaurar os volumes (edge functions)
```bash
cp -r volumes/* /root/projects/prospecta/docker/volumes/
```

### 4. Reiniciar tudo
```bash
docker compose restart
docker restart rest
```

### 5. Acessar o sistema
- Login admin: Admin@admin.com / 132210
- Login cliente: diogo@zplug.com.br / 1q2w3e4r
- URL: https://prospecta.contatte.com.br
