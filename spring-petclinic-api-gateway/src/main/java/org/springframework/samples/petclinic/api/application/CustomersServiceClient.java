/*
 * Copyright 2002-2021 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.springframework.samples.petclinic.api.application;

import lombok.RequiredArgsConstructor;

import org.springframework.http.client.reactive.ReactorClientHttpConnector;
import org.springframework.samples.petclinic.api.dto.OwnerDetails;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

import io.netty.resolver.DefaultAddressResolverGroup;
import reactor.core.publisher.Mono;
import reactor.netty.http.client.HttpClient;

/**
 * @author Maciej Szarlinski
 */
@Component
@RequiredArgsConstructor
public class CustomersServiceClient {

    //without this modification, the webclient will not resolve the hostname on an internal network
    private final WebClient webClient = WebClient.builder().clientConnector(new ReactorClientHttpConnector(HttpClient.create().resolver(DefaultAddressResolverGroup.INSTANCE))).build();

    public Mono<OwnerDetails> getOwner(final int ownerId) {
        
        return webClient.get()
                .uri("http://customers-service:8081/owners/{ownerId}", ownerId)
                .retrieve()
                .bodyToMono(OwnerDetails.class);
    }
}
