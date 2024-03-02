import type { AppProps } from 'next/app';

import { Client, InternetIdentity } from '@bundly/ares-core';
import { IcpConnectContextProvider } from '@bundly/ares-react';

import { candidCanisters } from '@app/canisters';

export default function MyApp({ Component, pageProps }: AppProps) {
    const client = Client.create({
        agent: {
            host: process.env.NEXT_PUBLIC_ICP_HOST!
        },
        candidCanisters,
        providers: [
            new InternetIdentity({
                providerUrl: process.env.NEXT_PUBLIC_INTERNET_IDENTITY_URL!
            })
        ]
    });

    return (
        <IcpConnectContextProvider client={client}>
            <Component {...pageProps} />
        </IcpConnectContextProvider>
    )
}
