# Guia de APIs e Serviços

O ecossistema é composto por três microsserviços especializados:
- [donation][1]: Gerencia o fluxo de doações.
- [ngo][2]: Cadastro e gestão das ONG's parceiras.
- [volunteer][3]: Gestão de voluntariados.

As comunicações utilizam mensageria (SQS) e persistência NoSQL (DynamoDB) ou Relacional (Postgres), dependendo do contexto de domínio.

[1]: https://github.com/rodx64/pos_arch/tree/develop/fase_5/tech_challenge/solidary-tech/services/donation-service
[2]: https://github.com/rodx64/pos_arch/tree/develop/fase_5/tech_challenge/solidary-tech/services/ngo-service
[3]: https://github.com/rodx64/pos_arch/tree/develop/fase_5/tech_challenge/solidary-tech/services/volunteer-service
