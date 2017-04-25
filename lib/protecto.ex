defmodule Protecto do
    @moduledoc """
      Common helper functions for filtering and validation of Ecto Changeset's.
    """

    @doc """
      Change the given string field to lowercase.
    """
    @spec format_lowercase(Ecto.Changeset.t, atom) :: Ecto.Changeset.t
    def format_lowercase(changeset, field) do
        case changeset do
            %Ecto.Changeset{ valid?: true, changes: %{ ^field => value } } when is_binary(value) -> Ecto.Changeset.put_change(changeset, field, String.downcase(value))
            _ -> changeset
        end
    end

    @doc """
      Change the given string field to uppercase.
    """
    @spec format_uppercase(Ecto.Changeset.t, atom) :: Ecto.Changeset.t
    def format_uppercase(changeset, field) do
        case changeset do
            %Ecto.Changeset{ valid?: true, changes: %{ ^field => value } } when is_binary(value) -> Ecto.Changeset.put_change(changeset, field, String.upcase(value))
            _ -> changeset
        end
    end

    @doc """
      Hash the given string field, and pass it into the field name followed by
      `_hash`.
    """
    @spec format_hash(Ecto.Changeset.t, atom) :: Ecto.Changeset.t
    def format_hash(changeset, field), do: format_hash(changeset, field, String.to_atom(to_string(field) <> "_hash"))

    @doc """
      Hash the given string field, and pass it into the hash_field.
    """
    @spec format_hash(Ecto.Changeset.t, atom, atom) :: Ecto.Changeset.t
    if Code.ensure_loaded?(Comeonin) do
        def format_hash(changeset, field, hash_field) do
            case changeset do
                %Ecto.Changeset{ valid?: true, changes: %{ ^field => value } } when is_binary(value) -> Ecto.Changeset.put_change(changeset, hash_field, Comeonin.Bcrypt.hashpwsalt(value))
                _ -> changeset
            end
        end
    else
        def format_hash(_, _, _), do: raise "format_hash/3 requires Comeonin package"
    end

    @doc """
      Validate the given string field is formatted correctly as an
      [E.164 compliant](https://en.wikipedia.org/wiki/E.164) phone number.
    """
    @spec validate_phone_number(Ecto.Changeset.t, atom) :: Ecto.Changeset.t
    def validate_phone_number(changeset, field) do
        case changeset do
            %Ecto.Changeset{ changes: %{ ^field => <<"+", numbers :: binary>> } } ->
                digits = String.length(numbers)
                if (digits >= 1) and (digits <= 18) do
                    case Regex.match?(~r/\D/, numbers) do
                        false -> changeset
                        true -> Ecto.Changeset.add_error(changeset, field, "should contain the country prefix followed by only digits", [validation: :phone_number])
                    end
                else
                    Ecto.Changeset.add_error(changeset, field, "should contain between 1 and 18 digits", [validation: :phone_number])
                end
            %Ecto.Changeset{ changes: %{ ^field => value } } when is_binary(value) -> Ecto.Changeset.add_error(changeset, field, "should begin with a country prefix", [validation: :phone_number])
            _ -> changeset
        end
    end

    @doc """
      Validate the given string field is loosely formatted correctly as an
      email.
    """
    @spec validate_email(Ecto.Changeset.t, atom) :: Ecto.Changeset.t
    def validate_email(changeset, field) do
        case changeset do
            %Ecto.Changeset{ changes: %{ ^field => email } } when is_binary(email) ->
                if Regex.match?(~r/.+@.+/, email) do
                    changeset
                else
                    Ecto.Changeset.add_error(changeset, field, "should contain a local part and domain separated by '@'", [validation: :email])
                end
            _ -> changeset
        end
    end

    @doc """
      Validate the emptiness of a field, requiring that the field is not empty.
    """
    @spec validate_emptiness(Ecto.Changeset.t, atom) :: Ecto.Changeset.t
    def validate_emptiness(changeset, field) do
        case changeset do
            %Ecto.Changeset{ changes: %{ ^field => nil } } -> Ecto.Changeset.add_error(changeset, field, "should not be empty", [validation: :emptiness])
            _ -> changeset
        end
    end

    @doc """
      Validate the given map field contains the given fields.
    """
    @spec validate_map(Ecto.Changeset.t, atom, [atom]) :: Ecto.Changeset.t
    def validate_map(changeset, field, required_fields) do
        case changeset do
            %Ecto.Changeset{ changes: %{ ^field => map } } when is_map(map) ->
                if Enum.all?(required_fields, &Map.has_key?(map, &1)) do
                    changeset
                else
                    Ecto.Changeset.add_error(changeset, field, "should contain all of the required fields", [validation: :map])
                end
            _ -> changeset
        end
    end
end
