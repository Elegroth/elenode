FROM amazonlinux:2-with-sources

EXPOSE 22
EXPOSE 3333
EXPOSE 6000
EXPOSE 8090

RUN mkdir -p /home/ec2-user/setup

COPY ./scripts/ /home/ec2-user/setup/
RUN chmod -R +x /home/ec2-user/setup/*.sh

ENV NODE_CONFIG=testnet
ENV NODE_HOME=/cardano
ENV INSTALL_HOME=/home/ec2-user/
ENV USERNAME=cardano

RUN /home/ec2-user/setup/init.sh
RUN /home/ec2-user/setup/cardano.sh
RUN /home/ec2-user/setup/services.sh
RUN /home/ec2-user/setup/extras.sh

USER admin

RUN /home/ec2-user/setup/cardobot.sh
RUN /home/ec2-user/setup/clean-up.sh

COPY entrypoint.sh /opt/entrypoint.sh

USER root

CMD [ "/bin/bash", "/opt/entrypoint.sh" ]