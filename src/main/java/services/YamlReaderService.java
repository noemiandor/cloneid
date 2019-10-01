package services;

import cloneid.Manager;
import org.apache.commons.io.FilenameUtils;
import services.dto.YamlConfigDTO;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;
import com.fasterxml.jackson.dataformat.yaml.YAMLGenerator;
import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;
import java.net.URISyntaxException;

public class YamlReaderService {

    private YamlConfigDTO config;
    private String yamlDir;
    private ObjectMapper mapper;

    public YamlReaderService() {
        this.yamlDir = getYamlDir();
        this.mapper = new ObjectMapper(new YAMLFactory().disable(YAMLGenerator.Feature.WRITE_DOC_START_MARKER));
        readYAML();
    }

    private void readYAML() {
        try {
            config = mapper.readValue(new File(yamlDir), YamlConfigDTO.class);
        } catch (Exception e) {
            System.out.println(e.getMessage());
        }
    }

    public void writeYAML(String newConfig) {
        try {
            PrintWriter out = new PrintWriter(yamlDir);
            out.println(newConfig);
            out.close();
        } catch (IOException e) {
            System.out.println(e);
        }
    }

    public String getYamlDir() {

        String yaml_url = "";

        try {
            String pth = new File(Manager.class.getProtectionDomain().getCodeSource().getLocation().toURI()).getPath();
            pth = FilenameUtils.getFullPath(pth);
            yaml_url = pth + "../config/config.yaml";
        } catch (URISyntaxException u) {
            System.err.println("Cannot find config.yaml");
            System.exit(1);
        }

        return yaml_url;
    }

    public void setYamlDir(String yamlDir) {
        this.yamlDir = yamlDir;
    }

    public YamlConfigDTO getConfig() {
        return config;
    }

    public void setConfig(YamlConfigDTO config) {
        this.config = config;
    }

    @Override
    public String toString() {
        return "YamlReaderService{" +
                "yamlDir='" + yamlDir + '\'' +
                '}';
    }

}
