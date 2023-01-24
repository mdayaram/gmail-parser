#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require "http"
require "date"
require "json"

class JoplinApi
    attr_reader :token, :server, :inbox_id

    def initialize(token)
        @token = token
        @server = "http://localhost:41184"
        @inbox_id = "a54a7f2e4c50405ca074538fe3f64066"
        populate_tag_cache!
    end

    def ping
        get("/ping", {}, true)
    end

    def create_note(title:, body:, date:, tags: [])
        unixtime = date.to_time.to_i * 1000
        payload = {
            title: title,
            body: body,
            user_created_time: unixtime,
            user_updated_time: unixtime,
            parent_id: inbox_id,
        }
    
        note = post("/notes", payload)
        
        tags.each do |tagname|
            tag_payload = {id: note["id"]}
            t = find_or_create_tag(tagname)
            post("/tags/#{t["id"]}/notes", tag_payload)
        end

        note
    end

    # { "id" => "abcdefg", "title" => "tagname" }
    def find_tag(tagname)
        @tag_cache[tagname.downcase]
    end

    def find_or_create_tag(tagname)
        exists = find_tag(tagname)
        return exists unless exists.nil?
        
        # create the tag.
        post("/tags", title: tagname)

        populate_tag_cache!
        find_tag(tagname)
    end

    private

    def populate_tag_cache!
        @tag_cache = {}
        has_more = true
        page = 1
        while has_more
            results = get("/tags", {page: page})
            results["items"].each do |item|
                @tag_cache[item["title"].downcase] = item
            end
            has_more = results["has_more"]
            page += 1
        end
    end

    def request(verb, path, json_body: nil, query: {}, raw: false)
        full_path = File.join(server, path)
        query = query.merge(token: token)

        response = nil
        if verb == "GET"
            response = HTTP.get(full_path, params: query)
        elsif verb == "POST"
            response = HTTP.post(full_path, json: json_body, params: query)
        else
            raise "Unknown verb: #{verb}"
        end

        if response.code >= 400
            raise "HTTP Error #{response.code}: #{response.to_s}"
        end
        
        if raw
            response.to_s
        else
            JSON.parse(response.to_s)
        end
    end

    def get(path, query = {}, raw = false)
        request("GET", path, query: query, raw: raw)
    end

    def post(path, json_body = nil, query = {}, raw = false)
        request("POST", path, json_body: json_body, query: query, raw: raw)
    end
end