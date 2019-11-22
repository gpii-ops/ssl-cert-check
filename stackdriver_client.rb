require "google/cloud/monitoring"

module StackdriverClient

  @project_id = ENV['PROJECT_ID']

  def self.process_result(results_file)
    metric_service_client = Google::Cloud::Monitoring::Metric.new(version: :v3)
    formatted_name = Google::Cloud::Monitoring::V3::MetricServiceClient.project_path(@project_id)

    begin
      results = File.read(results_file).scan(/(([a-z_]*?){(.*?)}\s(\d+))/)
    rescue
      puts "[ERROR]: Results file is unreadable or malformed!"
      exit 1
    end

    time_series = []
    time = Time.now.to_i

    results.each do |metric|
      metric_name = metric[1]
      metric_labels = metric[2]
      metric_value = metric[3]

      labels = {"project_id" => "#{@project_id}"}
      metric_labels.split(",").each do |label|
        label = label.match(/^(.*?)="(.*?)"$/)
        labels[label[1]] = label[2]
      end

      time_series << {
        "metric" => {
          "type" => "custom.googleapis.com/ssl-cert-check/#{metric_name}",
          "labels" => labels,
        },
        "resource" => {
          "type" => "global",
        },
        "metric_kind" => "GAUGE",
        "value_type" => "DOUBLE",
        "points" => [
          {
            "interval" => {
              "end_time" => {
                "seconds" => time,
                "nanos" => 0
              }
            },
            "value" => {
              "double_value" => metric_value.to_f
            }
          }
        ]
      }
    end

    begin
      metric_service_client.create_time_series(formatted_name, time_series)
    rescue Google::Gax::RetryError => err
      puts "[ERROR]: Error while submitting metrics to Stackdriver (Google::Gax::RetryError)."
      puts err.message
      exit 120
    end
  end
end


# vim: set et ts=2 sw=2:
