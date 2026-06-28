import clsx from 'clsx';
import Heading from '@theme/Heading';
import styles from './styles.module.css';
import { HandCoins, Users, Server, Activity, type LucideIcon } from 'lucide-react';
import type { ReactNode } from 'react';

interface FeatureProps {
  Icon: LucideIcon;
  title: string;
  description: ReactNode;
}

const FeatureList: { title: string; Icon: LucideIcon; description: ReactNode }[] = [
  {
    title: 'Serviço de Doação',
    Icon: HandCoins,
    description: (
      <>
        Fluxo principal de doações e transações da ONG. Otimizado com mensageria SQS.
      </>
    ),
  },
  {
    title: 'Serviços de Voluntariado & ONG',
    Icon: Users,
    description: (
      <>
        Gestão de cadastro de voluntários e ONGs parceiras, unificando a rede de apoio.
      </>
    ),
  },
  {
    title: 'Infraestrutura',
    Icon: Server,
    description: (
      <>
        Provisionamento automatizado via Terraform e Terragrunt com estratégia Multi-Ambiente.
      </>
    ),
  },
  {
    title: 'Observabilidade',
    Icon: Activity,
    description: (
      <>
        Detecção de anomalias com AIOps via Datadog, garantindo saúde constante do EKS.
      </>
    ),
  },
];

function Feature({ Icon, title, description }: FeatureProps) {
  return (
    <div className={clsx('col col--3')}>
      <div className="text--center">
        <Icon size={48} className={styles.featureSvg} />
      </div>
      <div className="text--center padding-horiz--md">
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures() {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
