# Publicar no GitHub pelo Windows

Este pacote ja contem todos os arquivos da entrega e **um unico script PowerShell** para limpar o conteudo atual do repositorio e publicar a versao corrigida.

## 1. Extraia o ZIP

Extraia `PW2_GitHub_ENTREGA_FINAL.zip` para uma pasta comum, por exemplo `Downloads` ou `Documentos`.

## 2. Abra o PowerShell na pasta extraida

Entre na pasta `PW2_GitHub_ENTREGA_FINAL` e execute:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\publicar_github.ps1
```

## 3. Confirme a limpeza

O script mostrara um aviso. Digite exatamente:

```text
LIMPAR
```

Isso confirma que os arquivos atualmente existentes no repositorio `uesb-academicos/PW2` podem ser removidos e substituidos pelos arquivos deste pacote.

**Importante:** o script nao usa `git push --force` e nao apaga o historico de commits. A limpeza e registrada em um novo commit normal do Git.

## 4. Login no GitHub

Se o Git Credential Manager abrir o navegador, entre na conta que possui permissao de escrita no repositorio e autorize o acesso.

## 5. Resultado

Repositorio:

`https://github.com/uesb-academicos/PW2`

GitHub Pages, se estiver configurado em `main / (root)`:

`https://uesb-academicos.github.io/PW2/`

Documento de entrega:

`https://uesb-academicos.github.io/PW2/entrega.html`
