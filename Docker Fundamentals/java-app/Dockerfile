FROM eclipse-temurin:21

WORKDIR /app

COPY HelloWorld.java ./
RUN javac HelloWorld.java

EXPOSE 8080
CMD ["java", "HelloWorld"]
