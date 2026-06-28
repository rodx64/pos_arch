const sidebars = {
  tutorialSidebar: [
    { type: 'doc', id: 'intro', label: '🏠 Introdução' },
    { type: 'doc', id: 'architecture', label: '🏗️ Arquitetura' },
    {
      type: 'category',
      label: '⚙️ Infraestrutura e CI/CD',
      items: [
        'infra/terraform-terragrunt',
        'infra/pipelines-cicd',
      ],
    },
    {
      type: 'category',
      label: '📖 Como usar',
      items: [
        'how-to/apis-services',
        'how-to/local-env',
      ],
    },
    { type: 'doc', id: 'observability', label: '👁️ Observabilidade' },
    { type: 'doc', id: 'sre', label: '🛡️ SRE' },
    { type: 'doc', id: 'finops', label: '💰 FinOps' },
    { type: 'doc', id: 'itsm-aiops', label: '🤖 AIOps' },
  ],
};

module.exports = sidebars;
