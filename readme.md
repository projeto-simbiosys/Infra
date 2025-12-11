# Infraestrutura do projeto SIMBIOSYS

<p align="center">
  <img src="https://imgur.com/6s2lH3n.png" alt="Simbiosys Logo">
</p>

<br>

**Para rodar essa infraestrutura siga o seguinte roteiro abaixo:**

1. **Obtenha as Credenciais da AWS** <br>
   Antes de começar a configurar o ambiente, você precisará das credenciais da AWS para acessar os serviços necessários. Se estiver utilizando um laboratório ou ambiente temporário, acesse o terminal execute o comando abaixo para exibir as credenciais:

   - **Atenção:** Essas credenciais podem mudar sempre que você iniciar um novo laboratório ou sessão. Certifique-se de obter as novas credenciais toda vez que começar um novo lab. <br><br>

   ```
   cat ~/.aws/credentials
   ```

<br>

2. **Configure o AWS CLI** <br>
   Com as credenciais em mãos, você precisará configurar a AWS CLI (Command Line Interface) para interagir com a AWS. Isso pode ser feito usando qualquer terminal, como PowerShell, Bash ou CMD. Digite o comando abaixo no terminal e siga as instruções para inserir a Access Key, Secret Key e a região desejada:

   ```
   aws configure
   ```

<br>

3. **Definindo Chaves, Região, Sessão e Token**
   1. **AWS Access Key ID** <br>
      Insira a chave de acesso obtida no passo anterior.
   2. **AWS Secret Access Key** <br>
      Insira a chave secreta correspondente.
   3. **Default region name** <br>
      Especifique a região (ex.: us-east-1).
   4. **Default output format** <br>
      Deixe como json ou outro formato de sua preferência
   5. **(Opcional, se aplicável) Defina o Token da Sessão** <br>
      Se você precisar de um token de sessão (comumente usado em ambientes temporários ou seguros), use o comando abaixo para configurar e substitua `<<token>>` pelo valor do token de sessão fornecido.<br><br>
   ```
   aws configure set aws_session_token <<token>>
   ```

<br>

4. **Crie uma chave .pem na raiz do projeto com o comando**

   ```
   ssh-keygen -m PEM -t rsa -b 4096 -f key_simbiosys.pem
   ```

<br>

5. **Rode os seguintes comandos na raiz do projeto**

   1. **Para iniciar o terraform**

   ```
   terraform init
   ```

   2. **Para aplicar a configuração do terraform**
      <br>
      Sera exibido um resumo do que sera aplicado pelo terraform, basta confirmar digitando "yes" no terminal.

      OBS: após toda a configuração ser aplicada, tera um certo tempo de espera a mais para que o projeto todo esteja UP

   ```
   terraform apply
   ```

<br>

6. **Desfazendo o terraform:**<br>
   Sera exibido um resumo do que sera revertido pelo terraform, basta confirmar digitando "yes" no terminal.
   <br>

   ```
   terraform destroy
   ```
