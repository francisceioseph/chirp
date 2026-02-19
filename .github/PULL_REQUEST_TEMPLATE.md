## 🚀 Descrição do PR

### 🎯 O que foi feito?
- 

### 🏗️ Mudanças na Arquitetura (Clean Arch)
Selecione as camadas impactadas:
- [ ] **Domain**: Entidades, Interfaces de Repositório ou Use Cases.
- [ ] **Data/Infra**: Implementação de Repositórios, Stores (Nests) ou Services.
- [ ] **Presentation**: Controllers (Chat, Friendship, Presence, Chirp) ou Widgets.

### 🛠️ Lista de Alterações Técnicas
- [ ] **Separação de Responsabilidades**: O `ChirpController` agora atua apenas como orquestrador.
- [ ] **Unificação de Estado**: Integração entre `TielNestRepository` e `ConversationNest` (Store).
- [ ] **Desacoplamento**: Controllers não se referenciam mais diretamente.

### 🧪 Como validar?
1. Execute o app e inicie os serviços de bando.
2. **Cenário A**: Validar se o `PresenceController` marca Tiels como *away* após 120s.
3. **Cenário B**: Enviar um Chirp e verificar se o `ChatController` atualiza a `TielStore`.
4. **Cenário C**: Solicitar amizade e validar o fluxo no `FriendshipController`.

### 📸 Evidências (Opcional)
---
*Enviado do VS Code no Linux 🐧*